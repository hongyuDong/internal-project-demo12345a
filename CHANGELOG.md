# Changelog

> 模板本身的版本变更记录

---

## [1.0.1] - 2026-06-21

### 🔧 Fixed（基于自我 Review）

- ✅ **修复 README 目录树与源目录不一致** — 统一 install.bat 复制路径，不再嵌套 `internal-project/`
- ✅ **重写 README.md** — 从 17 KB 精简到 8.7 KB，按角色组织索引
- ✅ **新增 `install.sh`** — macOS/Linux 安装脚本（之前只有 bat）
- ✅ **简化 install.bat 复制逻辑** — 用 `for` 循环统一处理 docs/ 子目录

### ✨ Added

- ✅ **GitHub Actions CI/CD**（`.github/workflows/`）：
  - `ci.yml` — YAML 校验 + OpenAPI spec 校验 + secret 扫描 + shellcheck
  - `release.yml` — Tag 触发自动创建 GitHub Release + 分发包
- ✅ **Issue 模板**（`.github/ISSUE_TEMPLATE/`）：
  - `bug_report.md` — Bug 报告
  - `feature_request.md` — 功能请求
- ✅ **OpenAPI 代码生成脚本**（`scripts/gen-openapi.{sh,bat}`）：
  - 支持 Python / Python-FastAPI / TypeScript / Go
  - 一键从 spec 生成客户端代码
- ✅ **`.gitignore`** — 完整的 Git 排除规则（51 行）
- ✅ **完整发布流程**：
  - `init-git.{sh,bat}` — 首次推送
  - `release.{sh,bat}` — 版本发布
  - `PUBLISHING.md` — 完整 Git 指南
- ✅ **修复 init-git.bat 闪退问题** — 去掉 `chcp` / `color` / `enabledelayedexpansion`
- ✅ **新增 `run-debug.bat`** — 调试运行器（捕获日志）

### 📝 Documentation

- ✅ **README.md** — 完整重写：
  - 源目录 = install 后目录（一致）
  - 按角色分（新人/开发/架构师/PM/SRE/EM）
  - 已知问题章节（v1.0.1 状态）
- ✅ **PUBLISHING.md** — Git 发布完整指南
- ✅ **CHANGELOG.md** — 本文件

### ⚠️ Known Issues

- 🟡 ADR 编号跳号（0001/0002/0003/**0005**，缺 0004）— 待补
- 🟡 `.sh` hooks 在 Windows 不能直接跑 — 需要 WSL/Git Bash
- 🟢 没 Pydantic 模型 — 这是模板不是框架（设计如此）

---

## [1.0.0] - 2026-06-21

### 🎉 Initial Release

86 文件 / 644 KB 完整 Claude Code 企业模板：

- 8 sub-agents + 7 skills + 8 hooks + 7 commands
- 20 OpenAPI 端点 + 18 业务规则 + 4 ADR
- 10 个 Runbook + 完整测试策略
- Windows 安装脚本 + 一键 Git 推送

---

## 版本管理

- **MAJOR**: 不兼容变更（如重写 hooks 架构）
- **MINOR**: 兼容新功能（如新加 skill）
- **PATCH**: 文档/脚本修复（如本次）

详细发布流程见 [PUBLISHING.md](PUBLISHING.md)。
