# internal-user-service — Claude Code Enterprise Template

> 企业级 Claude Code 项目模板（内部用户中心微服务为示例）

**92 文件 / 463 KB** · **OpenAPI 3.1 · Mermaid · RFC 7807 · BR-001~018**

---

## 🚀 5 分钟上手

### Step 1: 安装到你的项目

**Windows**：双击 `install.bat`，选模式 1（项目级安装）
**macOS/Linux**：
```bash
./install.sh  # 或手动复制（见 INSTALL.md）
```

### Step 2: 修改项目记忆

```bash
code CLAUDE.md                              # 替换项目名 / 技术栈
code docs/requirements/business-rules.md    # 替换业务规则
```

### Step 3: 启动 Claude Code

```bash
claude
> 实现 PROJ-XXXX  # Claude 自动按 CLAUDE.md 工作流程执行
```

---

## 📂 项目结构（源目录 = install 后目录，一致）

```
internal-project/
├── CLAUDE.md                              ⭐ 项目记忆 + 工作流程
├── README.md                              ⭐ 本文件
├── install.bat                            ⭐ Windows 一键安装
├── uninstall.bat                          ⭐ Windows 快速卸载
├── install.sh                             ⭐ macOS/Linux 安装
├── init-git.bat / init-git.sh             ⭐ Git 推送
├── release.bat / release.sh               ⭐ 版本发布
├── INSTALL.md                             安装说明
├── PUBLISHING.md                          Git 发布指南
├── CHANGELOG.md                           变更日志
├── .gitignore                             Git 排除规则
├── .mcp.json.example                      MCP 配置模板
│
├── .claude/                               ⭐ Claude Code 配置（32 文件）
│   ├── settings.json                      权限沙箱 + hooks 配置
│   ├── settings.local.json.example        本地覆盖示例
│   ├── agents/                            8 个子代理
│   │   ├── security-reviewer.md           安全审查
│   │   ├── api-designer.md                API 设计
│   │   ├── test-engineer.md               测试工程
│   │   ├── db-migrator.md                 DB 迁移
│   │   ├── product-owner.md               ⭐ 业务理解
│   │   ├── architect.md                   ⭐ 架构审查
│   │   ├── planner.md                     ⭐ 任务拆解
│   │   └── tracker.md                     ⭐ 进度跟踪
│   │
│   ├── skills/                            7 个技能
│   │   ├── deploy-staging/                部署 staging
│   │   ├── create-new-endpoint/           新建端点（13 步）
│   │   ├── run-incident/                  事故响应（Runbook）
│   │   ├── decompose-requirement/         ⭐ 需求拆解
│   │   ├── plan-execution/                ⭐ 路径规划
│   │   ├── update-progress/               ⭐ 进度更新
│   │   └── create-adr/                    ⭐ ADR 编写
│   │
│   ├── commands/                          7 个斜杠命令
│   │   ├── pr-review.md                   PR 审查
│   │   ├── release.md                     发版
│   │   ├── db-migrate.md                  DB 迁移
│   │   ├── plan.md                        ⭐ 规划任务
│   │   ├── decompose.md                   ⭐ 拆解需求
│   │   ├── track.md                       ⭐ 查看进度
│   │   └── retro.md                       ⭐ 复盘
│   │
│   └── hooks/                             8 个安全钩子
│       ├── secret-scanner.sh              密钥扫描（30+ 模式）
│       ├── bash-policy.sh                 危险命令拦截
│       ├── audit-log.sh                   审计日志
│       ├── auto-format.sh                 自动格式化
│       ├── notify-slack.sh                Slack 通知
│       ├── pre-plan-check.sh              ⭐ 任务前检查
│       ├── post-task-update.sh            ⭐ 任务后更新
│       └── doc-sync-check.sh              ⭐ 文档同步
│
├── docs/                                  ⭐ 文档（44 文件）
│   ├── requirements/                      产品需求（4）
│   │   ├── PRD.md                         产品愿景 + 场景 + KPI
│   │   ├── business-rules.md              18 条业务规则
│   │   ├── acceptance-criteria.md         验收模板
│   │   └── user-stories/
│   │       └── PROJ-1001-login.md         完整用户故事
│   │
│   ├── domain/                            领域模型（5）
│   │   ├── glossary.md                    业务术语表
│   │   ├── domain-model.md                实体 + 状态机 + 不变式
│   │   └── entities/
│   │       ├── user.md                    User 详解
│   │       ├── organization.md            Organization 详解
│   │       └── permission.md              Permission/Role 详解
│   │
│   ├── architecture/                      架构（13）
│   │   ├── overview.md                    系统架构总览
│   │   ├── data-flow.md                   6 个核心数据流
│   │   ├── deployment.md                  K8s + CI/CD + DR
│   │   ├── integrations.md                外部集成
│   │   ├── diagrams/                      架构图（3）
│   │   │   ├── er-diagram.md              ER 图 + 索引策略
│   │   │   ├── sequence-login.md          登录时序图
│   │   │   └── sequence-onboard.md        入职时序图
│   │   └── adr/                           架构决策记录（4）
│   │       ├── 0001-why-postgresql.md
│   │       ├── 0002-why-event-driven.md
│   │       ├── 0003-jwt-vs-session.md
│   │       └── 0005-permission-cache.md   ⚠️ 0004 暂缺
│   │
│   ├── project/                           项目管理（4）
│   │   ├── roadmap.md                     4 季度路线图
│   │   ├── sprint-backlog.md              当前 Sprint
│   │   ├── changelog.md                   版本变更日志
│   │   └── postmortems/
│   │       └── template.md                事故复盘模板
│   │
│   ├── api/                               API 契约（4）
│   │   ├── openapi.yaml                   OpenAPI 3.1 主规范
│   │   ├── openapi.json                   JSON 版
│   │   ├── README.md                      使用说明
│   │   └── changelog.md                   API 变更日志
│   │
│   ├── runbook/                           事故应急（11）
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
│   └── testing/                           测试策略（4）
│       ├── README.md                      测试金字塔
│       ├── strategy.md                    完整策略
│       ├── e2e-scenarios.md               10 个 E2E 场景
│       └── load-testing.md                压测 + 容量规划
│
└── .planning/                             ⭐ 任务规划（4 文件）
    ├── README.md
    └── current/
        ├── task_plan.md                   任务主计划模板
        ├── notes.md                       调研笔记模板
        └── progress.md                    进度 + 复盘模板
```

> 📌 **重要**：源目录结构 = install 后的目录结构。团队 clone 后无需重新理解"模板 vs 实际"的差异。

---

## 🎯 核心特性（8 层防护 + 8 层上下文）

### 8 层上下文
1. **业务上下文** — PRD / 规则 / 术语 / 实体
2. **架构上下文** — Overview / ADR / 数据流
3. **API 契约** — OpenAPI 3.1 + Webhooks
4. **流程可视化** — ER + 时序图（Mermaid）
5. **事故响应** — 10 个 Runbook
6. **测试方法论** — 金字塔 + E2E + 压测
7. **规划系统** — task_plan / 4 skill / 4 agent
8. **安全沙箱** — Settings + 8 hooks

### 5 层安全
1. settings.json 权限（allow/deny/ask）
2. Hooks 实时拦截（密钥/Bash/审计/格式化/通知）
3. Sub-agent 只读审查（security-reviewer）
4. 审计日志（不可篡改）
5. PII 加密 + 软删（合规）

---

## 📚 按角色文档索引

| 角色 | 必读 |
|------|------|
| 🆕 **新人** | CLAUDE.md → README.md → architecture/overview.md → domain/glossary.md |
| 👨‍💻 **开发** | docs/api/openapi.yaml → runbook/README.md → testing/strategy.md |
| 🏗 **架构师** | architecture/overview.md → data-flow.md → adr/ |
| 📊 **PM** | requirements/PRD.md → business-rules.md → project/roadmap.md |
| 🚨 **SRE** | runbook/ → architecture/deployment.md → testing/load-testing.md |
| 👔 **EM** | CLAUDE.md → .planning/README.md → runbook/README.md |

---

## 🛠 常用工作流

### 新建功能
```
> 实现 PROJ-XXXX 新功能

Claude 自动：
1. 读 CLAUDE.md（工作流程）
2. 调 product-owner + architect 验证
3. 调 planner 拆解到 task_plan.md
4. 用 create-new-endpoint skill 实现
5. 跑测试（参考 testing/strategy.md）
6. 部署 staging（参考 deploy-staging skill）
7. /retro 复盘 + 归档
```

### 处理事故
```
> P0: 用户登录失败

Claude 自动：
1. 读 runbook/login-failure.md
2. 按 Runbook 4 步执行
3. 24h 内 postmortem
```

### 写 ADR
```
> 我们要不要从 PostgreSQL 迁到 MySQL？

Claude 自动：
1. 调 create-adr skill
2. 读现有 ADR
3. 列备选 + 决策矩阵
4. 写入 adr/NNNN-why-mysql.md
```

---

## 🆘 常见问题

### Q: 修改配置后没生效？
A: 检查 `settings.local.json`（git ignored）覆盖，或重启 Claude Code。

### Q: Claude 不读我的 docs？
A: 在 prompt 里明确说"先读 CLAUDE.md 和 docs/ 后再回答"。

### Q: Hooks 没触发？
A: 检查 `.sh` 文件权限（`chmod +x`），Windows 下用 WSL/Git Bash。

### Q: 业务规则怎么改？
A: 改 `docs/requirements/business-rules.md`，通知团队，更新引用。

### Q: OpenAPI 跟代码不同步？
A: 跑 `make gen-models` 重新生成 Pydantic 模型（见 scripts/）。

---

## 🤝 贡献

见 [PUBLISHING.md](PUBLISHING.md)。

---

## 📜 版本

**v1.0.1** · 2026-06-21 · 主入口文档

详细变更见 [CHANGELOG.md](CHANGELOG.md)。

---

## 📞 联系

- **Slack**: `#user-service-dev`
- **Jira**: `PROJ` 项目
- **On-call**: PagerDuty

---

## ⚠️ 已知问题（v1.0.1）

| 问题 | 说明 | 状态 |
|------|------|------|
| ADR-0004 缺失 | 跳号（0001/0002/0003/0005） | 🟡 待补 |
| .sh 脚本在 Windows | 需要 WSL/Git Bash | 🟡 已知 |
| 没 Pydantic 模型 | 这是模板不是框架 | 🟢 设计如此 |

详见 [CHANGELOG.md](CHANGELOG.md)。

---

## 📄 License

内部使用 · Proprietary · © 2026 Company
