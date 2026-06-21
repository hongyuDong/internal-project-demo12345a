# Governance — 项目治理

> 谁维护、谁决策、怎么发布、怎么支持

---

## 👥 维护者

### Core Maintainers

| 角色 | 团队 | 职责 |
|------|------|------|
| **Template Owner** | @devex-team | 整体架构 + 发布决策 |
| **API Lead** | @api-team | `docs/api/` + OpenAPI |
| **Architecture Lead** | @arch-team | `docs/architecture/` + ADR |
| **Security Lead** | @security-team | `SECURITY.md` + Hooks + Settings |
| **SRE Lead** | @sre-team | `docs/runbook/` |
| **QA Lead** | @qa-team | `docs/testing/` |
| **Product Lead** | @product-team | `docs/requirements/` |

### Contact

- **Slack**: `#claude-template-feedback`
- **Email**: `devex-team@company.com`
- **Issue Tracker**: GitHub Issues

---

## 📅 Release Cadence

| 类型 | 频率 | 内容 |
|------|------|------|
| **Major** (`v2.0.0`) | 季度（必要时）| 破坏性变更 |
| **Minor** (`v1.1.0`) | 月度 | 新功能（向后兼容）|
| **Patch** (`v1.0.1`) | 按需 | Bug 修复 + 文档 |

**SLA**：
- 🔴 Critical 修复：24h
- 🟡 High 修复：3 天
- 🟢 Medium 修复：7 天
- ⚪ Low 修复：下次 release

---

## 🗳️ 决策流程

### 日常决策（无需会议）

Maintainer 可直接合并 PR：
- 文档修复
- 拼写错误
- 链接修复
- 小幅样式调整

### 标准决策（1 个 Approver）

代码修改需要：
- 至少 1 个 CODEOWNER 批准
- CI 全绿
- 无新增依赖（除非 ADR 批准）

### 重大决策（2 个 Approver）

需要 2 个 maintainer 批准：
- 新增 hook（影响所有用户）
- 修改 `settings.json` 权限
- 修改 ADR
- 发布 Major 版本

### 破坏性决策（3 个 Approver）

需要 3 个 maintainer 批准 + Slack 公告：
- 改 hooks 架构
- 改 OpenAPI 命名
- 删除任何文件
- 移除任何 hook / agent / skill

---

## 🚨 事故响应

### 报告安全漏洞

见 [SECURITY.md](SECURITY.md)

### 报告 Bug

- GitHub Issues（公开）
- Slack `#claude-template-feedback`（内部讨论）

### 紧急情况

- Slack `#claude-template-oncall`（如有）
- Email `devex-team@company.com`

---

## 📋 团队采用流程

### 第 1 步：评估

团队评估是否需要这个模板：
- 读 [README.md](README.md)
- 看 [docs/api/openapi.yaml](docs/api/openapi.yaml) 例子
- 看 [CLAUDE.md](CLAUDE.md) 工作流程
- 评估工作量（通常 1-2 天集成）

### 第 2 步：试点

```
1. 在测试项目里 clone 本模板
2. 运行 install.bat（项目级安装）
3. 跑 1-2 个 sprint 试用
4. 收集反馈
```

### 第 3 步：正式采用

```
1. 提交 RFC（包含：使用范围、定制需求、ROI 估算）
2. RFC 评审（DevEx Team + Tech Lead）
3. 正式 fork 到团队仓库
4. 加入 ROADMAP（哪个版本）
5. 季度 review
```

---

## 📊 采用度指标

我们追踪：

| 指标 | 目标 | 当前 |
|------|------|------|
| 团队采用数 | 10+ | _ |
| 项目数 | 30+ | _ |
| 月活用户 | 50+ | _ |
| 平均节省时间 | 30 min/任务 | _ |
| 事故率降低 | 50% | _ |

数据来源：GitHub Insights + 季度问卷

---

## 🔄 升级策略

### 项目升级（新版本发布后）

```
1. 查看 CHANGELOG.md 的 Breaking Changes
2. 阅读 UPGRADE_GUIDE.md（如有 Major 版本）
3. 在测试项目先试
4. 评估影响范围
5. 走 PR 流程升级
```

### Claude Code 升级时

```
1. 看 Claude Code release notes
2. 检查 settings.json schema 是否变
3. 检查 hooks API 是否兼容
4. 在测试项目验证
5. 必要时更新 hooks
```

### 团队反馈循环

```
季度收集：
- 哪些 hook 太严格？
- 哪些文档没人读？
- 哪些 skill 不够用？
- 缺什么 agent？

→ 加入下一个 Minor 版本
```

---

## 🤝 合作规范

### 贡献（修改模板）

- 读 [CONTRIBUTING.md](CONTRIBUTING.md)
- Fork → Feature 分支 → PR
- 至少 1 个 CODEOWNER 批准
- CI 全绿

### 提问 / 反馈

- Slack `#claude-template-feedback`
- 每周三 16:00 有 office hours
- GitHub Issues 公开讨论

### 教学

- 月度分享会（最后一个周五）
- 新人 onboarding 必读
- Workshop 资料在 [docs/workshop/](docs/workshop/)

---

## 📞 SLA（支持响应时间）

| 严重度 | 首次响应 | 修复 SLA | 通知 |
|--------|----------|----------|------|
| 🔴 P0 (生产挂) | 1h | 4h | 电话 + Slack |
| 🟡 P1 (功能受损) | 4h | 1 周 | Slack |
| 🟢 P2 (小问题) | 1 天 | 下次 release | Slack |
| ⚪ P3 (优化) | 1 周 | Backlog | 邮件 |

**工作时间**：周一至周五 9:00-18:00  
**非工作时间**：仅 P0（on-call）

---

## 📜 版本历史

| 版本 | 日期 | Maintainer | 变更 |
|------|------|------------|------|
| v1.0.0 | 2026-06-21 | @devex-team | 初始版本 |
| v1.0.1 | 2026-06-21 | @devex-team | 自我 Review 修复 |
| v1.0.2 | 2026-06-21 | @devex-team | 跨平台一致性 |
| v1.0.3 | 2026-06-21 | @devex-team | 完整治理 + 代码骨架 |

---

## 🔗 相关文档

- [README.md](README.md) — 项目门户
- [CLAUDE.md](CLAUDE.md) — Claude 工作流程
- [CONTRIBUTING.md](CONTRIBUTING.md) — 贡献指南
- [SECURITY.md](SECURITY.md) — 安全策略
- [CHANGELOG.md](CHANGELOG.md) — 变更历史
- [PUBLISHING.md](PUBLISHING.md) — 发布流程
- [.github/CODEOWNERS](.github/CODEOWNERS) — 自动 Reviewer
- [UPGRADE_GUIDE.md](docs/UPGRADE_GUIDE.md) — 升级指南
