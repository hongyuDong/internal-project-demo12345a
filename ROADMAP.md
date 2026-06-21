# ROADMAP — Claude Code 企业模板路线图

> **模板自身**的演化计划（不是产品 roadmap）  
> **当前版本**: v1.0.3  
> **最后更新**: 2026-06-21  
> **Owner**: @devex-team

---

## 📅 时间线总览

```
2026 Q3          2026 Q4          2027 Q1          2027 Q2          2027 H2
7-9 月           10-12 月         1-3 月           4-6 月           7-12 月
─────            ─────            ─────            ─────            ─────
v1.1.0           v1.2.0           v2.0.0           v2.1.0           v3.0.0

多语言 +        自适应 +         Declarative      Plugin          Industry
SDK 模板         模板生成器       Config           Marketplace      Leader
```

---

## ✅ v1.0.3 — 基础完成（2026-06-21）

### 已交付

- ✅ 完整模板（125 文件 / 545 KB）
- ✅ 8 sub-agents + 7 skills + 14 hooks（7 .sh + 7 .ps1）
- ✅ 业务 + 架构 + API + 测试 + Runbook 完整文档
- ✅ 跨平台（Windows + macOS/Linux）
- ✅ CI/CD（GitHub Actions）
- ✅ OpenAPI 3.1 + 代码生成
- ✅ FastAPI 代码骨架
- ✅ 治理体系（SECURITY + LICENSE + CONTRIBUTING + GOVERNANCE + CODEOWNERS + UPGRADE_GUIDE）
- ✅ 安装 / Git 推送 / 发布自动化

### 已知遗留

- 🟡 多语言（Go/Java/Node）示例缺失
- 🟡 没有集成测试套件
- 🟡 没有项目级 onboarding
- 🟡 缓存策略相对简单

---

## 🎯 v1.1.0 — 扩语言 + 质量（2026 Q3 / 7-9 月）

**主题**：让更多团队能用（多语言）+ 让现有团队更稳（集成测试）

### 主要功能

#### 🥇 多语言 SDK / 模板（4 周）

| 语言 | 模板 | 关键组件 |
|------|------|----------|
| **Go** | `templates/go/` | main.go + gin + sqlx |
| **Java** | `templates/java/` | Spring Boot + JPA |
| **Node** | `templates/node/` | NestJS + Prisma |

每个模板包含：
- 项目骨架（main + config + API）
- 适配 OpenAPI spec 的代码生成
- settings.json 模板
- README 启动指南

#### 🥈 集成测试套件（2 周）

- `tests/integration/` — 用真实 Claude Code 测试 hooks
- `tests/e2e/` — 模拟完整 PR 流程
- `tests/fixtures/` — 测试数据
- CI 中跑（每次 PR 必须通过）

#### 🥉 智能缓存增强（1 周）

- 按用户频率分层 TTL（高频 5min / 低频 30min）
- 缓存预热（启动时加载热点用户）
- 缓存击穿保护（singleflight）

### 验收标准

- [ ] 4 种语言模板就绪（含 OpenAPI 生成）
- [ ] 集成测试覆盖率 ≥ 70%
- [ ] 缓存命中率提升到 95%+

---

## 🔧 v1.2.0 — 自适应 + 工具链（2026 Q4 / 10-12 月）

**主题**：让模板更"聪明"（按项目类型自适应）+ 让团队更容易用（工具链）

### 主要功能

#### 🥇 智能项目类型检测（3 周）

`install.sh` 会自动检测项目类型：

```
检测到 → 推荐配置：
- FastAPI 项目 → FastAPI hook + 测试模板
- Express 项目 → Node hook + 测试模板
- Go + Gin → Go hook + 测试模板
- Spring Boot → Java hook + 测试模板
- 纯 Python 库 → 简化配置（无 API）
- 未知项目 → 默认通用配置
```

#### 🥈 模板生成器 CLI（2 周）

```bash
# 主人
npx create-claude-project my-new-app --type=fastapi
# 自动：
# 1. 从模板生成项目骨架
# 2. 复制 .claude/ + CLAUDE.md
# 3. 生成 OpenAPI 客户端
# 4. 跑 smoke test
```

发布到 npm：`@company/create-claude-project`

#### 🥉 Workshop 材料（1 周）

- `docs/workshop/` — 30 分钟团队上手材料
- 视频脚本（让 DevEx 团队录视频）
- 实战练习项目
- 常见错误 FAQ

### 验收标准

- [ ] install.sh 自动检测项目类型
- [ ] CLI 工具发布到 npm
- [ ] Workshop 在 5 个团队试点

---

## 🚀 v2.0.0 — 声明式配置 + 插件（2027 Q1 / 1-3 月）

**主题**：从"模板"升级为"框架"（用户可配置 + 第三方插件）

### 主要功能

#### 🥇 Declarative Configuration（6 周）

把 `settings.json` + hooks 配置全部移到 YAML：

```yaml
# .claude/config.yml
permissions:
  allow: [Read, Grep, Glob]
  deny: [Bash(rm -rf*)]
  
hooks:
  pre_tool_use:
    - name: secret-scanner
      type: built-in
      config:
        patterns: [aws, github, anthropic, ...]
  
  post_tool_use:
    - name: auto-format
      type: plugin
      plugin: company/formatter-py
```

#### 🥈 插件系统（4 周）

```yaml
# 第三方插件可以定义 hooks/agents/skills/commands
plugins:
  - name: company/security-extra
    hooks:
      - secret-scanner-enhanced
    agents:
      - security-auditor-pro
```

#### 🥉 BR-NNN 用户可配置（2 周）

业务规则不再硬编码在文档里：

```yaml
# .claude/br-nnn.yml
rules:
  - id: BR-001
    description: "邮箱唯一"
    enforcement: db_unique_constraint
  - id: BR-002
    description: "工号唯一"
    enforcement: db_unique_constraint
```

### 验收标准

- [ ] 所有配置 YAML 化
- [ ] 插件市场 MVP（10 个内部插件）
- [ ] 至少 3 个团队从 v1.x 升级到 v2.0

### ⚠️ 破坏性变更

- v1.x → v2.0 需要迁移工具
- 部分 hook API 变化
- 详见 UPGRADE_GUIDE_v2.0.md

---

## 🌐 v2.1.0 — 插件市场 + 远程配置（2027 Q2 / 4-6 月）

**主题**：让团队可以共享 + 发现配置

### 主要功能

#### 🥇 内部插件市场

- Web UI 浏览 + 搜索插件
- 一键安装（`claude plugin install xxx`）
- 评分 + 评论
- 自动安全扫描

#### 🥈 远程配置中心

- 团队级 settings.json（中央管理）
- 强制规范（如：公司必须用某个 hook）
- 例外申请（特殊项目可豁免）

#### 🥉 VS Code 扩展

- 可视化配置 hooks
- 一键生成 `task_plan.md`
- 实时显示 Claude 在做什么

### 验收标准

- [ ] 至少 20 个内部插件
- [ ] 至少 10 个团队接入远程配置
- [ ] VS Code 扩展发布到 Marketplace

---

## 🏆 v3.0.0 — 行业领先（2027 H2）

### 愿景

- 🎯 **行业标准**：成为 Claude Code 在企业落地的参考实现
- 🎯 **生态丰富**：100+ 插件，覆盖各种语言/框架/场景
- 🎯 **AI 驱动**：AI 自动推荐配置 + 自动检测问题
- 🎯 **开源贡献**：回馈给 Claude Code 官方

### 主要功能

- AI 自动优化 hooks（基于使用数据）
- 智能推荐 BR-NNN（基于项目分析）
- 跨 Claude Code 版本兼容
- 多 AI 助手支持（不只是 Claude Code）

---

## 🗳️ 候选功能 Backlog

> 投票决定优先级

| 功能 | 请求者 | 票数 | 优先级 |
|------|--------|------|--------|
| Go/Java/Node 模板 | @team-a | 12 | 🥇 高 |
| 远程配置中心 | @sre-team | 10 | 🥇 高 |
| VS Code 扩展 | @frontend-team | 8 | 🥈 中 |
| 模板生成器 CLI | @new-teams | 7 | 🥈 中 |
| 集成测试套件 | @qa-team | 6 | 🥈 中 |
| Workshop 视频 | @devex-team | 5 | 🥉 低 |
| AI 智能推荐 | @ai-team | 4 | 🥉 低 |
| 插件市场 Web UI | @devex-team | 3 | 🥉 低 |
| 行业标准 PR | @cto | 2 | 🔵 远期 |
| 开源版 | @cto | 1 | 🔵 远期 |

**投票方式**：在 [GitHub Discussions](https://github.com/company/claude-code-template/discussions) 投票

---

## 📊 成功指标（关键 KPI）

| 指标 | 目标（2027 H2） | 当前 | 趋势 |
|------|----------------|------|------|
| 团队采用数 | 30+ | 1 (devex) | 🟢 |
| 项目数 | 100+ | 1 | 🟢 |
| 月活开发者 | 200+ | 5 | 🟢 |
| 平均节省时间 | 30 min/任务 | TBD | - |
| 事故率降低 | 80% | TBD | - |
| 插件数 | 50+ | 0 | - |
| 满意度 (NPS) | 50+ | TBD | - |

---

## 🤝 协作

### 如何参与

- **提需求**：GitHub Issues
- **投票**：GitHub Discussions
- **贡献代码**：Fork → PR
- **分享经验**：月度 Office Hours（每月最后一周三 16:00）
- **教学**：Workshop（季度）

### 社区

- **Slack**: `#claude-template-community`
- **GitHub**: https://github.com/company/claude-code-template
- **Office Hours**: 每月最后一个周三 16:00
- **Wiki**: https://wiki.company.com/claude-code-template

---

## ⚠️ 风险与依赖

| 风险 | 影响 | 缓解 |
|------|------|------|
| Claude Code 大版本破坏兼容性 | 🔴 高 | 兼容性矩阵 + 适配层 |
| 内部团队采用不足 | 🟡 中 | Office Hours + 培训 + 案例分享 |
| 维护者精力不足 | 🟡 中 | 培养更多贡献者 |
| 安全漏洞 | 🔴 高 | 安全审计 + 自动扫描 |
| 第三方插件质量差 | 🟡 中 | 审核 + 评分 + 自动测试 |

---

## 📅 发布节奏

| 类型 | 频率 | 时间 |
|------|------|------|
| **Major** (v2.0, v3.0) | 季度 | 季末 |
| **Minor** (v1.1, v1.2) | 月度 | 月初 |
| **Patch** (v1.0.4) | 按需 | 24h 内 |
| **Hotfix** | 紧急 | P0 立即 |

---

## 🎯 季度里程碑

### 2026 Q3（v1.1.0）

- [ ] 多语言模板（Go/Java/Node）
- [ ] 集成测试套件
- [ ] 智能缓存增强
- [ ] 至少 3 个团队采用

### 2026 Q4（v1.2.0）

- [ ] 智能项目类型检测
- [ ] CLI 工具（npm）
- [ ] Workshop 完整材料
- [ ] 至少 10 个团队采用

### 2027 Q1（v2.0.0）

- [ ] Declarative Config（YAML）
- [ ] 插件系统 MVP
- [ ] BR-NNN 可配置
- [ ] v1.x → v2.0 迁移工具

---

## 📞 联系

- **Slack**: `#claude-template-community`
- **Email**: `devex-team@company.com`
- **Office Hours**: 月度

---

**维护者**: DevEx Team  
**更新频率**: 每月  
**下次 review**: 2026-07-21
