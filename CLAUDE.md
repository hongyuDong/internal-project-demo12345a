# internal-user-service

> 企业内部用户中心微服务 — Claude Code 项目记忆

## 📋 工作流程（强制 — 任何任务前必读）

**Claude 接到任何任务时，必须按以下 4 步执行**。跳过任何一步会被 `pre-plan-check` hook 警告。

### Step 1: 理解需求 🔍

开始前**必须**读：

| 必读 | 作用 |
|------|------|
| `docs/requirements/PRD.md` | 产品愿景 + 核心场景 |
| `docs/requirements/business-rules.md` | 业务规则编号（BR-NNN）|
| `docs/domain/glossary.md` | 业务术语统一 |
| `docs/domain/domain-model.md` | 实体 + 状态机 |
| `docs/requirements/user-stories/PROJ-XXXX.md` | 当前用户故事（如有） |
| `docs/architecture/overview.md` | 系统架构总览 |
| 相关 ADR（`docs/architecture/adr/NNNN-*.md`）| 架构决策历史 |

**强制使用 sub-agent 验证**：
- `product-owner` — 验证业务理解、覆盖所有 AC
- `architect` — 评估架构影响、强制写 ADR

**Socratic 5 问**（需求不清时必须问）：
1. 给谁用？2. 解决什么问题？3. 成功标准？4. 不做什么？5. 依赖/约束？

### Step 2: 规划路径 📋

**任何动手前**必须创建 `.planning/current/task_plan.md`，包含：

- ✅ 目标（一句话）
- ✅ 验收标准（Given/When/Then）
- ✅ 子任务（每个 ≤ 30 分钟，有完成标准）
- ✅ 决策记录（引用 BR-NNN / ADR-NNNN）
- ✅ 风险评估（🟢/🟡/🔴）
- ✅ 回滚方案

**使用 skill**：
- `decompose-requirement` — 拆解需求
- `plan-execution` — 生成依赖图 + 里程碑
- `create-adr` — 写架构决策

**强制 4 个里程碑**：
- **M1 调研**: 读上下文 + profile 现状
- **M2 设计**: 写 ADR + 评审
- **M3 实施**: 编码 + 测试
- **M4 验证**: 部署 staging + PM 验收

**每个 M 必须停下来**等用户确认，再进下一个。

### Step 3: 执行 ⚙️

**每个 subtask 完成后**，自动调用 `update-progress` skill：

1. 更新 `task_plan.md` 复选框
2. 追加关键发现到 `notes.md`
3. 更新 `progress.md` 时间线 + 百分比
4. 通知（如里程碑 / 阻塞 / 风险变化）

**使用 sub-agent 跟踪**：
- `planner` — 拆解
- `tracker` — 跟踪（自动检测阻塞 / 风险升级）

**自动 hook**：
- `pre-plan-check.sh` — 动手前检查规划完整性
- `post-task-update.sh` — 任务后自动更新进度
- `doc-sync-check.sh` — 检查代码与文档同步

### Step 4: 验证 ✅

- [ ] 单元测试 + 集成测试通过
- [ ] 覆盖率达标（≥ 85%）
- [ ] 部署 staging + 冒烟测试
- [ ] PM 在 staging 验收
- [ ] 部署 prod（如适用）
- [ ] 24 小时监控无异常

### Step 5: 归档 📦

任务完成后：
1. 跑 `/retro` 写经验教训
2. 把 `.planning/current/` 移到 `.planning/archive/YYYY-MM-DD-{slug}/`
3. 更新 `docs/project/changelog.md`
4. Slack 通知 `#user-service-dev`

---

## 🚦 状态流转

```
需求 → [Step 1 理解] → [Step 2 规划] → [Step 3 执行] → [Step 4 验证] → [Step 5 归档]
         ↓                  ↓                ↓                ↓              ↓
       product-owner    planner +        tracker          e2e tests      /retro
       architect        architect                          staging       archive
```

---

## ⚠️ 合规优先

本项目处理员工个人信息和权限数据，所有变更必须：
- 关联 Jira 工单（格式：`PROJ-1234`）
- 经过 PR Review（至少 1 个 Approver）
- 通过 CI：lint + test + security-scan
- **禁止**直接 push 到 main
- **禁止**提交 `.env` / `credentials*` / `*.key` / `id_rsa`

## 技术栈

| 层 | 选型 | 说明 |
|----|------|------|
| 语言 | Python 3.11 | type hints 强制 |
| Web | FastAPI 0.110+ | async 优先 |
| ORM | SQLAlchemy 2.0 | async session |
| 数据库 | PostgreSQL 15 | 主库 + 2 个只读副本 |
| 缓存 | Redis 7 | session + rate limit |
| 消息 | Kafka | 用户事件流（user.created / user.deleted） |
| 部署 | Kubernetes | namespace: `user-service` |
| 监控 | Prometheus + Grafana | 业务指标见 `docs/metrics.md` |

## 目录约定

```
src/
├── api/                  # FastAPI 路由
│   └── v1/
│       ├── users.py
│       ├── auth.py
│       └── organizations.py
├── core/                 # 配置、安全、依赖
│   ├── config.py
│   ├── security.py
│   └── deps.py
├── models/               # SQLAlchemy 模型
├── schemas/              # Pydantic schema
├── services/             # 业务逻辑层
├── repositories/         # 数据访问层
├── events/               # Kafka 生产/消费
└── utils/

tests/
├── unit/
├── integration/
└── e2e/

migrations/              # Alembic 迁移
```

## 常用命令

```bash
# 开发
make dev                 # 启 FastAPI + 监听 reload
make test                # 跑全部测试
make test-unit           # 仅单元测试
make lint                # ruff + mypy
make format              # black + isort

# 数据库
make db-migrate MSG="..." # alembic upgrade head
make db-rollback          # alembic downgrade -1
make db-shell             # psql 进库

# 部署（需审批）
make deploy-staging       # kubectl apply -k overlays/staging
make deploy-prod          # kubectl apply -k overlays/prod
```

## 代码规范

### 必须遵守
- 所有 API 必须有 OpenAPI 描述（`summary` + `description`）
- 所有写操作必须有 `@audit_log` 装饰器
- 所有外部输入必须 Pydantic 校验
- 所有 SQL 必须用参数化（禁字符串拼接）
- 所有 `async def` 必须真正 await，禁止 sync IO
- 所有公开函数必须有 type hints

### 命名约定
- 文件：`snake_case.py`
- 类：`PascalCase`
- 函数/变量：`snake_case`
- 常量：`UPPER_SNAKE_CASE`
- 数据库表：`snake_case` 复数（`users`, `organizations`）

### 错误处理
- API 层：抛 HTTPException，detail 用结构化 dict
- 服务层：抛自定义异常（`UserNotFoundError` 等）
- 仓储层：让 SQLAlchemy 异常向上抛，不吞

## 数据安全红线 🚨

- **PII 字段**（email / phone / id_card）查询必须走 `PIIAccessLog`
- **密码**：禁止日志打印，禁止返回 API response
- **Token**：HttpOnly Cookie + Secure + SameSite=Strict
- **密钥**：从 Vault 读取，**永远**不写在代码里
- **删除用户**：软删（`deleted_at`），禁止硬删
- **审计**：所有权限变更必须留痕

## 与其他服务的关系

| 服务 | 关系 | 接口 |
|------|------|------|
| auth-service | 下游（依赖） | gRPC: `AuthService` |
| notification-service | 下游 | Kafka: `notification.requested` |
| audit-service | 下游 | Kafka: `audit.events` |
| hr-system | 上游（被依赖） | REST: `/v1/employees` |
| sso-service | 上游 | OIDC |

## Gotchas ⚠️

1. **时区**：数据库统一存 UTC，API 层转 ISO 8601 + 用户时区
2. **大表查询**：用户表 5000 万行，所有 list 必须分页 + 索引
3. **缓存一致性**：Redis 是 cache 不是 source of truth，DB 为准
4. **Kafka 顺序**：同 `user_id` 的事件必须同 partition（key=user_id）
5. **Kubernetes**：readiness probe 必须检查 DB 连接，不是单纯 TCP
6. **冷启动**：JIT 预热 5s，slow query 不能用 first request 衡量
7. **并发更新**：用户信息用乐观锁（`version` 字段）

## 联系人

- **On-call**：PagerDuty → `user-service-oncall`
- **Slack**：`#user-service-dev`
- **邮件**：user-service@company.com
- **架构 Review**：`@arch-review` 组

## 相关文档

- API 文档：`docs/api.md`
- 数据库 ER：`docs/er.md`
- 部署 Runbook：`docs/runbook.md`
- 事故响应：`docs/incident.md`
- Claude Code 使用规范：`docs/claude-usage.md`
