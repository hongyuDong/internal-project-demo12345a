# Pull Request

> 请填写以下内容。CI 会自动检查必填项。

---

## 📋 描述

简要说明改了什么、为什么改。

## 🔗 关联

- Issue: #XXX
- ADR: docs/architecture/adr/NNNN-...
- 业务规则: BR-NNN
- 工单: PROJ-XXXX

## 🎯 变更类型

请勾选（可多选）：

- [ ] 🐛 Bug 修复（fix）
- [ ] ✨ 新功能（feat）
- [ ] 📝 文档（docs）
- [ ] ♻️ 重构（refactor）
- [ ] ⚡ 性能优化（perf）
- [ ] 🧪 测试（test）
- [ ] 🔧 配置/工具（chore / ci）
- [ ] 🔒 安全修复（security）

## 📂 影响范围

请勾选受影响的目录：

- [ ] `.claude/agents/` — 新增/修改 agent
- [ ] `.claude/skills/` — 新增/修改 skill
- [ ] `.claude/commands/` — 新增/修改 command
- [ ] `.claude/hooks/` — 新增/修改 hook
- [ ] `.claude/settings.json` — 权限/hook 配置
- [ ] `docs/` — 文档
- [ ] `scripts/` — 脚本
- [ ] `.planning/` — 规划文件
- [ ] 其他: __________

## ✅ 自检清单

提交前请确认：

- [ ] 代码遵循 `.editorconfig` 和现有风格
- [ ] 改动跨平台测试过（Linux + Windows 如果改 hook）
- [ ] CI 全绿（lint + test + secret 扫描 + shellcheck）
- [ ] `CHANGELOG.md` 已更新
- [ ] 关联文档已更新（如改 API / 配置 / ADR）
- [ ] 不包含密钥 / 凭据 / PII

## 🧪 测试

描述如何测试这次改动：

```bash
# 步骤 1
# 步骤 2
# 预期结果
```

## 📸 截图 / 录屏

如果适用，附上。

## ⚠️ 破坏性变更

- [ ] 这是破坏性变更（不向后兼容）
- [ ] 已更新迁移指南（如需要）
- [ ] 已通知相关团队

---

🤖 **自动检查**（CI 跑）：
- [ ] 文件格式（yamllint / JSON 校验）
- [ ] Shell 脚本（shellcheck + bash -n）
- [ ] OpenAPI spec 合法（如改了 docs/api/）
- [ ] 无密钥泄漏
- [ ] CHANGELOG.md 已更新

🤖 Generated with [Claude Code](https://claude.com)
