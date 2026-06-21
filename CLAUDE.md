# internal-user-service — Claude Code 项目记忆

> 内部用户中心微服务 — 这是 **Claude Code 的"上下文",不是"命令"**  
> 遇到模糊任务时，Claude 应该问；遇到明确任务时，直接做。

---

## 🚦 工作流程分级（不是一刀切）

### 🟢 软性建议（默认遵守，但可以灵活）

> 这些是最佳实践，遇到简单问题不必硬套

- **简单问答**（"这个 API 怎么用？"、"X 是什么意思？"）→ 直接答，不建 task_plan
- **小修改**（改一行、5 分钟内）→ 直接改 + 简短 commit message
- **重命名 / 移动文件** → 直接做
- **查文档**（"BR-XXX 是什么"）→ 直接读 docs/

### 🟡 推荐（中等任务）

> 10 分钟 - 2 小时的改动，建议建个简单 task_plan

- **新加 skill**（如 create-new-endpoint）
- **修改 agent**（如 security-reviewer）
- **添加新 endpoint**（如 1-2 个 API）
- **小重构**

### 🔴 强制（重大任务）

> 这些必须建完整 task_plan + 4 个里程碑 + 评审

- **改架构**（新服务、新中间件）
- **改数据模型**（用户、组织、权限结构）
- **写 ADR**（任何架构决策）
- **处理 P0 事故**
- **跨服务改动**（影响其他团队）

---

## 📋 强制任务的标准流程（仅适用 🔴 级别）

### Step 1: 理解需求 🔍

**软建议**：开始前读相关 docs

```
推荐读:
- docs/requirements/PRD.md           产品愿景 + 场景
- docs/requirements/business-rules.md 业务规则编号 BR-NNN
- docs/domain/glossary.md            业务术语
- docs/architecture/overview.md       系统架构
- 相关 ADR（docs/architecture/adr/）
```

**Socratic 5 问**（仅在需求不清时问，不清不问）：

1. 给谁用？2. 解决什么问题？3. 成功标准？4. 不做什么？5. 依赖/约束？

### Step 2: 规划路径 📋

**仅 🔴 级别**才需要完整 task_plan.md：

```markdown
# Task: <name> [PROJ-XXXX]

## 目标
<一句话>

## 验收标准
- [ ] AC-1: <具体可验证>
- [ ] AC-2: ...

## 子任务（每个 ≤ 30 分钟）
- [ ] 1. ...
- [ ] 2. ...

## 决策记录 + 风险 + 回滚
<简短>
```

### Step 3: 执行 ⚙️

**软建议**：每个 subtask 后更新 progress.md

**自动触发**（无需手动）：
- `post-task-update` hook 自动记录代码变更
- `doc-sync-check` hook 提醒文档同步
- `audit-log` hook 记录所有工具调用

### Step 4: 验证 ✅

**通用检查**：
- [ ] 测试通过（如果有）
- [ ] 文档更新（如改了 API / 配置）
- [ ] 没引入密钥泄漏（hook 已自动检查）
- [ ] 跨平台兼容（如改了 hook）

### Step 5: 归档 📦

**软建议**：重要任务跑 `/retro`，归档 `.planning/`

---

## 🤖 Sub-agents（按需调用）

| Agent | 何时调用 |
|-------|---------|
| `product-owner` | 不确定业务需求时验证 |
| `architect` | 不确定架构选择时验证 |
| `planner` | 复杂任务拆解 |
| `tracker` | 跟踪长期任务进度 |
| `security-reviewer` | 写安全相关代码后 |
| `api-designer` | 设计新 API |
| `test-engineer` | 写测试用例 |
| `db-migrator` | 写 DB migration |

**软建议**：能用常识判断的不调 sub-agent（小问题不要过度工程）。

---

## 🔧 Skills（按需触发）

| Skill | 触发 |
|-------|------|
| `decompose-requirement` | 复杂任务需要拆解 |
| `plan-execution` | 生成 DAG + 里程碑 |
| `update-progress` | 任务进度跟踪 |
| `create-adr` | 写架构决策 |
| `create-new-endpoint` | 完整新建 API |
| `deploy-staging` | 部署 staging |
| `run-incident` | P0/P1 事故 |

---

## 📚 文档索引（按角色）

| 角色 | 必读 |
|------|------|
| 新人 | README.md → docs/architecture/overview.md → docs/domain/glossary.md |
| 开发 | docs/api/openapi.yaml → docs/runbook/README.md → docs/testing/strategy.md |
| 架构 | docs/architecture/overview.md → data-flow.md → adr/ |
| PM | docs/requirements/PRD.md → business-rules.md → docs/project/roadmap.md |
| SRE | docs/runbook/ → docs/architecture/deployment.md |

---

## ⚠️ 合规（硬性）

- ❌ 不直接 push 到 main
- ❌ 不提交 `.env` / `credentials*` / `*.key` / `id_rsa`
- ✅ 所有变更关联 Jira 工单（PROJ-XXXX）
- ✅ PR 必须 review（至少 1 approver）
- ✅ CI 必须通过：lint + test + security-scan

---

## 🔒 安全红线（硬性）

| ❌ 永远不要 | 原因 |
|-----------|------|
| 写明文密钥到代码 | 密钥泄漏 |
| 跳过 secret-scanner 检查 | 误把密钥提交到 git |
| 执行 `rm -rf /` 等危险命令 | 数据丢失 |
| 跳过 CI 检查直接部署 | 引入 bug |
| 修改 PII 字段不加密 | 合规违规 |
| 用 admin 权限做无审计操作 | 内部威胁 |

---

## 🛡️ 常见任务示例

### 改一行代码
```
主人: 改 src/api/users.py:42 把 email 字段加 unique=True

Claude: 直接改 + 简短 commit message（不建 task_plan）
```

### 加一个 endpoint
```
主人: 加一个 GET /v1/users/search?q=xxx

Claude: 
1. 读 docs/api/openapi.yaml（看现有模式）
2. 写 endpoint + 测试
3. 更新 openapi.yaml
4. 简单 task_plan.md（不是完整 4 步）
5. PR
```

### 写架构决策
```
主人: 我们要不要从 PostgreSQL 迁到 MySQL？

Claude:
1. 调 create-adr skill
2. 读现有 ADR（0001-why-postgresql.md）
3. 写 ADR-NNNN-why-mysql.md（完整格式）
4. 列备选 + 决策矩阵
5. 等评审
```

### P0 事故
```
主人: 用户登录失败！

Claude:
1. 调 run-incident skill
2. 读 docs/runbook/login-failure.md
3. 按 Runbook 执行
4. 24h 内 postmortem
```

---

## 🤖 对 Claude 的话

- **不要过度工程**：简单问题简单答
- **不要硬套流程**：这是工具不是命令
- **不要凭感觉**：数据驱动、引用 BR-NNN / ADR-NNN
- **不确定就问**：用 Socratic 5 问
- **透明化决策**：把 trade-off 写出来让主人判断

主人是 20 年经验的量化分析师，会判断。

---

## 📞 联系

- **Slack**: `#user-service-dev`
- **Jira**: `PROJ` 项目
- **On-call**: PagerDuty
- **本模板反馈**: `#claude-template-feedback`
