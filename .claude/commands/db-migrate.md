---
description: Create and apply Alembic database migration
---

# /db-migrate

Create Alembic migration, validate, and apply to current environment.

## Workflow

### 1. 检测 model 变更

```bash
# 检查模型是否已改
git diff --name-only src/models/

if git diff --quiet src/models/; then
  echo "❌ 没有 model 变更，无需迁移"
  exit 0
fi

echo "📝 检测到 model 变更:"
git diff --name-only src/models/
```

### 2. 自动生成迁移

```bash
# 生成迁移
MIGRATION_MSG=$(git diff src/models/ | grep "^+" | grep -oP "class \K\w+" | head -1 | tr '[:upper:]' '[:lower:]')
[ -z "$MIGRATION_MSG" ] && MIGRATION_MSG="schema_change"

alembic revision --autogenerate -m "$MIGRATION_MSG"

MIGRATION_FILE=$(ls -t migrations/versions/*.py | head -1)
echo "📄 生成的迁移: $MIGRATION_FILE"
```

### 3. 🚨 必须人工 review

**自动生成的迁移不一定对**，必须人工检查：

```markdown
## Checklist (每项必须 ✅)

- [ ] upgrade() 完整对应 model 变更
- [ ] downgrade() 完整可逆
- [ ] 索引用了 CONCURRENTLY（参见 env.py 配置）
- [ ] NOT NULL 列分两步（先 nullable → 应用部署 → 再 NOT NULL）
- [ ] 没有破坏性操作（drop column / rename type / drop table）
- [ ] 大表 DDL 已和 DBA 确认
- [ ] 已通知所有依赖此表的服务
```

**让 db-migrator 子代理 review**：

调用 `.claude/agents/db-migrator.md` 给出的检查清单。

### 4. 选择环境

```bash
echo "选择部署环境:"
echo "  1) local (本地)"
echo "  2) staging"
echo "  3) production (需审批)"
read -p "选择 [1/2/3]: " ENV
```

### 5. 应用迁移（按环境）

#### Local
```bash
echo "🔧 应用到 local..."
alembic upgrade head

echo "🧪 验证..."
./scripts/verify-migration.sh local
```

#### Staging
```bash
echo "🔧 应用到 staging..."
./scripts/db-migrate-remote.sh staging

echo "🧪 验证..."
./scripts/verify-migration.sh staging

echo "📊 监控 30 分钟..."
./scripts/db-monitor-30min.sh staging
```

#### Production
```bash
# 双重确认
read -p "⚠️  确认应用到生产？输入 PROCEED: " CONFIRM
[ "$CONFIRM" = "PROCEED" ] || { echo "❌ 已取消"; exit 1; }

# 备份
echo "💾 备份生产数据库..."
./scripts/db-backup.sh production

# 应用
echo "🔧 应用到 production..."
./scripts/db-migrate-remote.sh production

# 验证
echo "🧪 验证..."
./scripts/verify-migration.sh production

# 监控
echo "📊 监控 1 小时..."
./scripts/db-monitor-1h.sh production

# 通知
./scripts/notify-slack.sh "#user-service-dev" \
  "✅ 生产迁移完成: $(basename $MIGRATION_FILE)"
```

### 6. 验证脚本

`./scripts/verify-migration.sh` 必须包含：

```bash
#!/bin/bash
set -e

ENV=$1
DB_URL=$(get_db_url $ENV)

echo "🔍 验证迁移: $ENV"

# 1. Alembic 状态
echo "1. Alembic 当前版本..."
alembic current

# 2. Schema 正确性
echo "2. 检查 schema..."
psql "$DB_URL" -c "\d+ users" | head -30

# 3. 索引存在
echo "3. 检查索引..."
psql "$DB_URL" -c "
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY indexname;
"

# 4. 数据完整性
echo "4. 检查 NOT NULL 违规..."
psql "$DB_URL" -c "
SELECT COUNT(*) FROM users WHERE <new_not_null_column> IS NULL;
"

# 5. 慢查询
echo "5. 检查是否有新慢查询..."
psql "$DB_URL" -c "
SELECT pid, query, query_start, state
FROM pg_stat_activity 
WHERE state = 'active' AND query_start < now() - interval '5 seconds';
"

echo "✅ 验证完成"
```

## 回滚

如果迁移后出问题：

```bash
# Staging / Local
alembic downgrade -1

# Production
./scripts/db-migrate-rollback.sh production

# 通知
./scripts/notify-slack.sh "#user-service-dev" "🚨 生产迁移已回滚"
```

## 输出报告

```markdown
## 数据库迁移报告

### 迁移文件
`migrations/versions/2026_06_21_xxxx_{msg}.py`

### 变更概要
- 表: users
- 改动: 加 department_id 索引
- 风险等级: 🟢 低

### 环境
- [x] Local - 成功
- [x] Staging - 成功
- [ ] Production - 待 EM 审批

### 验证结果
- [x] Schema 正确
- [x] 索引创建成功
- [x] 无 NOT NULL 违规
- [x] 无慢查询
- [x] 应用运行正常

### 回滚方案
`alembic downgrade -1`

### 通知
- 已通知: #user-service-dev
- 待通知: 依赖 users 表的下游服务
```
