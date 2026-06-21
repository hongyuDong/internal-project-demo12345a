# internal-user-service — Claude Code Enterprise Template

> 企业级 Claude Code 项目模板（内部用户中心微服务为示例）

**86 个文件 / 426 KB** · **OpenAPI 3.1 · Mermaid · RFC 7807 · BR-001~018**

---

## 🚀 5 分钟上手

### Step 1: 安装到你的项目

```bash
# Windows: 双击 install.bat，选模式 1（项目级安装）
# macOS/Linux:
./install.sh  # 见下方说明
```

### Step 2: 修改项目记忆

```bash
code CLAUDE.md  # 替换项目名、技术栈、规范
code docs/requirements/business-rules.md  # 替换业务规则
```

### Step 3: 启动 Claude Code

```bash
claude
> 实现 PROJ-XXXX  # Claude 会自动按工作流程执行
```

### Step 4: 让 Claude 读上下文

```
> 读 CLAUDE.md 和 docs/ 后，告诉我这个项目的核心架构
```

### Step 5: 开始干活

```
> 帮我加一个新 API 端点 POST /v1/users/bulk-import
```

---

## 📂 项目结构

```
internal-user-service/
├── CLAUDE.md                              ⭐ 项目记忆 + 工作流程（必读）
├── README.md                              ⭐ 本文件
├── install.bat                            ⭐ Windows 一键安装
├── uninstall.bat                          ⭐ Windows 快速卸载
├── INSTALL.md                             安装说明
├── .mcp.json.example                      MCP 服务器配置模板
│
├── .claude/                               ⭐ Claude Code 配置（33 文件）
│   ├── settings.json                      权限沙箱 + hooks 编排
│   ├── settings.local.json.example        本地覆盖示例
│   ├── agents/                            8 个子代理
│   │   ├── security-reviewer.md           安全审查（OWASP + 公司红线）
│   │   ├── api-designer.md                API 设计（OpenAPI 3.1）
│   │   ├── test-engineer.md               测试工程
│   │   ├── db-migrator.md                 DB 迁移
│   │   ├── product-owner.md               业务理解（⭐ 本模板）
│   │   ├── architect.md                   架构审查（⭐ 本模板）
│   │   ├── planner.md                     任务拆解（⭐ 本模板）
│   │   └── tracker.md                     进度跟踪（⭐ 本模板）
│   │
│   ├── skills/                            7 个技能
│   │   ├── deploy-staging/                部署 staging
│   │   ├── create-new-endpoint/           新建端点（13 步）
│   │   ├── run-incident/                  事故响应（8 步 Runbook）
│   │   ├── decompose-requirement/         需求拆解（⭐ 本模板）
│   │   ├── plan-execution/                路径规划（⭐ 本模板）
│   │   ├── update-progress/               进度更新（⭐ 本模板）
│   │   └── create-adr/                    ADR 编写（⭐ 本模板）
│   │
│   ├── commands/                          7 个斜杠命令
│   │   ├── pr-review.md                   PR 审查
│   │   ├── release.md                     发版
│   │   ├── db-migrate.md                  DB 迁移
│   │   ├── plan.md                        规划新任务（⭐ 本模板）
│   │   ├── decompose.md                   拆解需求（⭐ 本模板）
│   │   ├── track.md                       查看进度（⭐ 本模板）
│   │   └── retro.md                       复盘（⭐ 本模板）
│   │
│   └── hooks/                             8 个安全钩子
│       ├── secret-scanner.sh              密钥扫描（30+ 模式）
│       ├── bash-policy.sh                 Bash 策略
│       ├── audit-log.sh                   审计日志
│       ├── auto-format.sh                 自动格式化
│       ├── notify-slack.sh                Slack 通知
│       ├── pre-plan-check.sh              任务前检查规划（⭐ 本模板）
│       ├── post-task-update.sh            任务后更新进度（⭐ 本模板）
│       └── doc-sync-check.sh              文档同步检查（⭐ 本模板）
│
├── docs/                                  ⭐ 文档中心（44 文件）
│   │
│   ├── internal-project/                  业务级文档（25 文件）
│   │   ├── requirements/                  产品需求
│   │   │   ├── PRD.md                     产品愿景 + 场景 + KPI
│   │   │   ├── business-rules.md          18 条业务规则（BR-001~018）
│   │   │   ├── acceptance-criteria.md     验收模板（Given/When/Then）
│   │   │   └── user-stories/
│   │   │       └── PROJ-1001-login.md     完整用户故事示例
│   │   │
│   │   ├── domain/                        领域模型
│   │   │   ├── glossary.md                业务术语表（A-Z）
│   │   │   ├── domain-model.md            实体 + 状态机 + 不变式
│   │   │   └── entities/
│   │   │       ├── user.md                User 详解
│   │   │       ├── organization.md        Organization 详解
│   │   │       └── permission.md          Permission/Role 详解
│   │   │
│   │   ├── architecture/                  架构
│   │   │   ├── overview.md                系统架构总览
│   │   │   ├── data-flow.md               6 个核心数据流
│   │   │   ├── deployment.md              K8s + CI/CD + DR
│   │   │   ├── integrations.md            外部服务集成
│   │   │   └── adr/                       架构决策记录
│   │   │       ├── 0001-why-postgresql.md
│   │   │       ├── 0002-why-event-driven.md
│   │   │       ├── 0003-jwt-vs-session.md
│   │   │       └── 0005-permission-cache.md
│   │   │
│   │   └── project/                       项目管理
│   │       ├── roadmap.md                 4 季度路线图
│   │       ├── sprint-backlog.md          当前 Sprint
│   │       ├── changelog.md               版本变更日志
│   │       └── postmortems/
│   │           └── template.md            事故复盘模板
│   │
│   ├── api/                               API 级文档（4 文件）
│   │   ├── openapi.yaml                   OpenAPI 3.1 主规范（31 KB）
│   │   ├── openapi.json                   JSON 版（46 KB）
│   │   ├── README.md                      使用说明
│   │   └── changelog.md                   API 变更日志
│   │
│   ├── architecture/diagrams/             架构图（3 文件）
│   │   ├── er-diagram.md                  ER 图 + 索引策略
│   │   ├── sequence-login.md              登录时序图
│   │   └── sequence-onboard.md            入职时序图
│   │
│   ├── runbook/                           事故应急手册（11 文件）
│   │   ├── README.md                      总览
│   │   ├── api-error-rate-spike.md        🟡 P1
│   │   ├── login-failure.md               🔴 P0
│   │   ├── db-primary-failure.md          🔴 P0
│   │   ├── redis-down.md                  🟡 P1
│   │   ├── kafka-lag.md                   🟡 P1
│   │   ├── cache-poisoning.md             🟡 P1
│   │   ├── data-corruption.md             🔴 P0
│   │   ├── security-incident.md           🔴 P0
│   │   ├── performance-degradation.md     🟡 P1
│   │   └── third-party-outage.md          🟡 P1
│   │
│   └── testing/                           测试策略（4 文件）
│       ├── README.md                      测试金字塔
│       ├── strategy.md                    完整测试策略 + 例子
│       ├── e2e-scenarios.md               10 个 E2E 场景
│       └── load-testing.md                压测方案 + 容量规划
│
└── .planning/                             ⭐ 任务规划系统（4 文件）
    ├── README.md                          系统说明
    └── current/                           当前任务
        ├── task_plan.md                   任务主计划模板
        ├── notes.md                       调研笔记模板
        └── progress.md                    进度 + 复盘模板
```

---

## 🎯 核心特性

### Layer 1: 业务上下文
Claude 读 `docs/requirements/` + `docs/domain/` 后**真正懂业务**：
- 知道产品愿景 + KPI
- 知道 18 条业务规则编号（BR-NNN）
- 知道业务术语（不发明）
- 知道实体 + 状态机

### Layer 2: 架构上下文
Claude 读 `docs/architecture/` 后**真正懂系统**：
- 知道为什么选 PostgreSQL（ADR-0001）
- 知道为什么用事件驱动（ADR-0002）
- 知道 JWT vs Session 决策（ADR-0003）
- 知道权限缓存策略（ADR-0005）
- 知道数据流、部署架构、集成关系

### Layer 3: API 契约
`docs/api/openapi.yaml` 是**单一真相源**：
- 23 个端点
- 17 个 schemas
- 7 个 tags
- 完整 RFC 7807 错误格式
- BR-NNN 标注 + ADR 标注
- Webhooks（Kafka 事件）

### Layer 4: 流程可视化
Mermaid 图让 Claude **理解流程**：
- ER 图（11 个表）
- 登录时序图（9 步）
- 入职时序图（HR → 可用 ≤ 5min）

### Layer 5: 事故响应
`docs/runbook/` 让 Claude **知道出事故怎么办**：
- 10 种常见事故
- 每个都有：确认 → 缓解 → 验证 → 通知
- 关键 Runbook 有完整命令

### Layer 6: 测试方法论
`docs/testing/` 让 Claude **理解质量门禁**：
- 测试金字塔（500+ 单元 / 50+ 集成 / 5-10 E2E）
- 10 个关键 E2E 场景（Gherkin）
- 压测方案（Locust + k6）
- OWASP Top 10 覆盖

### Layer 7: 规划系统
`.planning/` 让 Claude **按计划执行**：
- 任何任务必须先建 `task_plan.md`
- 每个 subtask 2-5 分钟
- 自动更新进度（hook 触发）
- 完成后归档

### Layer 8: 安全沙箱（已有）
`.claude/settings.json` + `hooks/`：
- 4 层权限（allow/deny/ask/hook 拦截）
- 5 个原有 hook（密钥/Bash/审计/格式化/通知）
- 3 个新 hook（plan-check/progress/sync）

---

## 🛠 常用工作流

### 1. 新建功能

```
> 帮我加一个新 API 端点 POST /v1/users/bulk-import

Claude 会自动：
1. 读 CLAUDE.md（工作流程）
2. 读 docs/requirements/business-rules.md
3. 读 docs/api/openapi.yaml
4. 调 product-owner + architect 验证
5. 调 planner 拆解到 task_plan.md
6. 用 create-new-endpoint skill 实现
7. 跑测试（参考 docs/testing/）
8. 部署 staging（参考 deploy-staging skill）
9. /retro 复盘 + 归档
```

### 2. 处理事故

```
> P0: 用户登录失败

Claude 会自动：
1. 读 docs/runbook/login-failure.md
2. 按 Runbook 4 步执行
3. 调 run-incident skill
4. 24h 内 postmortem（参考 postmortems/template.md）
```

### 3. 部署生产

```
> 部署 v1.4.2 到 prod

Claude 会自动：
1. 调 /release 命令（参考 release.md）
2. 检查当前版本（CLAUDE.md / package.json）
3. 更新 CHANGELOG
4. 创建 release PR（需 2 approver）
5. 部署窗口检查（工作日 10-16）
6. Tag + 触发 release pipeline
7. 监控 24h
```

### 4. 写 ADR

```
> 我们要不要从 PostgreSQL 迁到 MySQL？

Claude 会自动：
1. 调 create-adr skill
2. 读现有 ADR（adr/0001-why-postgresql.md）
3. 列出备选 + 决策矩阵
4. 写入 docs/architecture/adr/NNNN-why-mysql.md
5. 标注：Superseded by ADR-NNNN（如接受迁移）
```

---

## 📚 文档索引（按角色）

### 🆕 新加入的工程师（Day 1）

1. [CLAUDE.md](CLAUDE.md) — 工作流程
2. [README.md](README.md) — 本文件
3. [docs/architecture/overview.md](docs/internal-project/architecture/overview.md) — 系统架构
4. [docs/domain/glossary.md](docs/internal-project/domain/glossary.md) — 业务术语

### 👨‍💻 开发工程师（日常）

- [docs/api/openapi.yaml](docs/api/openapi.yaml) — API 契约
- [docs/runbook/README.md](docs/runbook/README.md) — 出事故查这里
- [docs/testing/strategy.md](docs/testing/strategy.md) — 怎么写测试
- [internal-project/architecture/adr/](docs/internal-project/architecture/adr/) — 架构决策

### 🏗 架构师（设计阶段）

- [docs/architecture/overview.md](docs/internal-project/architecture/overview.md)
- [docs/architecture/data-flow.md](docs/internal-project/architecture/data-flow.md)
- [internal-project/architecture/adr/](docs/internal-project/architecture/adr/)
- [.planning/README.md](.planning/README.md) — 任务规划

### 📊 产品 / PM

- [docs/requirements/PRD.md](docs/internal-project/requirements/PRD.md)
- [docs/requirements/business-rules.md](docs/internal-project/requirements/business-rules.md)
- [docs/project/roadmap.md](docs/internal-project/project/roadmap.md)
- [docs/project/sprint-backlog.md](docs/internal-project/project/sprint-backlog.md)

### 🚨 SRE / On-call

- [docs/runbook/](docs/runbook/) — 10 个事故应急
- [docs/architecture/deployment.md](docs/internal-project/architecture/deployment.md)
- [docs/testing/load-testing.md](docs/testing/load-testing.md)

### 👔 Tech Lead / EM

- [CLAUDE.md](CLAUDE.md) — 工作流程
- [.planning/README.md](.planning/README.md)
- [docs/runbook/README.md](docs/runbook/README.md) — 事故升级

---

## 🔧 安装到你的项目

### Windows（推荐）

双击 `install.bat`，选模式 1（项目级安装）。

详见 [INSTALL.md](INSTALL.md)。

### macOS / Linux

```bash
# 用 Python 等价脚本（需要转换 install.bat）
# 或直接手动复制：
cp -r .claude/* your-project/.claude/
cp CLAUDE.md your-project/
cp -r docs/* your-project/docs/
cp -r .planning your-project/
chmod +x your-project/.claude/hooks/*.sh
```

---

## 🔒 安全原则

| 原则 | 实现 |
|------|------|
| **最小权限** | settings.json allow 白名单 |
| **纵深防御** | 5 + 3 个 hooks 实时拦截 |
| **不可篡改审计** | Kafka + S3 + HMAC 签名（BR-013）|
| **密钥隔离** | Vault，永不进代码 |
| **软删** | BR-012，7 年合规留存 |
| **PII 加密** | BR-011，AES-256-GCM |

---

## 📈 业务规则引用

每条业务规则有 `BR-NNN` 编号，被以下位置引用：

- API 端点（OpenAPI 的 `x-business-rules`）
- ADR 决策记录
- 代码注释
- 测试用例
- Postmortem 复盘

新增规则时同步更新所有引用。

---

## 🧪 测试覆盖目标

| 层 | 数量 | 覆盖率 |
|----|------|--------|
| 单元测试 | 500+ | ≥ 85% |
| 集成测试 | 50+ | ≥ 70% |
| E2E 测试 | 5-10 | 关键路径 100% |
| 性能 | 季度 | 详见 load-testing.md |

---

## 🆘 常见问题

### Q: 修改配置后没生效？
A: 检查 `settings.local.json`（git ignored）覆盖，或重启 Claude Code。

### Q: Claude 不读我的 docs？
A: 在 prompt 里明确说："先读 CLAUDE.md 和 docs/ 后再回答"。

### Q: hooks 没触发？
A: 检查 `.sh` 文件权限（`chmod +x`），Windows 下用 WSL。

### Q: 业务规则怎么改？
A: 改 [business-rules.md](docs/internal-project/requirements/business-rules.md)，通知团队，更新引用。

### Q: 怎么升级到新版本？
A: 看 [DISTRIBUTION.md](../DISTRIBUTION.md) 的"版本管理"章节。

---

## 🤝 贡献指南

### 修改流程

1. 创建 feature 分支
2. 改 docs/ 或 .claude/
3. 跑 install.bat 测试（如果改了配置）
4. 跑测试
5. PR + 1 个 Approve
6. 合并后通知团队

### 新增 ADR 模板

```bash
# 使用 create-adr skill
> 写 ADR：我们决定用 Redis 替代 Memcached
```

### 新增 Runbook

参考 [docs/runbook/README.md](docs/runbook/README.md) 的模板。

### 新增 Skill

```bash
mkdir -p .claude/skills/your-skill/
# 写 SKILL.md（YAML frontmatter + Markdown body）
```

---

## 📞 联系方式

- **Slack**: `#user-service-dev`
- **Issue Tracker**: Jira `PROJ` 项目
- **On-call**: PagerDuty
- **架构 Review**: `#arch-review`
- **本模板反馈**: `#claude-template-feedback`

---

## 📜 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| **v1.0** | 2026-06-21 | 初版 · 86 文件 / 426 KB |

---

## 📄 License

内部使用 · Proprietary · © 2026 Company
