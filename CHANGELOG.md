# Changelog

---

## [1.0.3] - 2026-06-21

### ✨ Added

- ✅ **4 个 PowerShell hooks**（完整 Windows 覆盖）：
  - `audit-log.ps1`
  - `auto-format.ps1`
  - `doc-sync-check.ps1`
  - `notify-slack.ps1`
- ✅ **SECURITY.md** — 漏洞报告流程 + 响应 SLA
- ✅ **LICENSE** — Proprietary 许可证（含第三方组件清单）
- ✅ **CONTRIBUTING.md** — 贡献指南 + Conventional Commits + 开发流程
- ✅ **`.github/PULL_REQUEST_TEMPLATE.md`** — PR 模板（含自检清单）
- ✅ **最小代码骨架**（`src/` + `requirements.txt`）：
  - `main.py` — FastAPI 应用入口（含 OpenAPI metadata）
  - `core/config.py` — pydantic-settings 配置
  - `core/security.py` — JWT 验证（按 ADR-0003）
  - `core/cache.py` — Redis 缓存（按 ADR-0005）
  - `models/user.py` — SQLAlchemy 模型（按 docs/domain/entities/user.md）
  - `api/v1/{auth,users,organizations}.py` — 路由骨架
  - `.env.example` — 环境变量模板
  - `README_CODE.md` — 代码骨架说明

### 🔧 Changed

- ✅ **CLAUDE.md 弱化强制** — 区分 🟢软建议 / 🟡推荐 / 🔴强制，Claude 灵活判断
- ✅ **settings.json 加注释** — 解释每类规则含义、hooks 顺序

### 📊 Statistics

- **Files**: 100 → **115** (+15)
- **Hooks**: 7 (.sh + .ps1) × 2 = **14 hook scripts**
- **Hooks 完整跨平台**: ✅ 7/7

---

## [1.0.2] - 2026-06-21

### 🔧 Fixed

- 补 ADR-0004（PII 加密策略）
- 修 release.sh 兼容 main/master
- 修 post-task-update.sh 不用 /tmp
- 新增 .editorconfig + .gitattributes

### ✨ Added

- 3 个 PowerShell hooks（secret-scanner / pre-plan-check / post-task-update）
- 填实 `.planning/current/` 示例

---

## [1.0.1] - 2026-06-21

### 🔧 Fixed

- 统一 install.bat 复制路径
- 重写 README.md（精简到 8.7 KB）

### ✨ Added

- GitHub Actions CI/CD
- Issue 模板
- OpenAPI 代码生成脚本

---

## [1.0.0] - 2026-06-21

### 🎉 Initial Release

86 文件 / 644 KB

---

## ⚠️ 已知问题（v1.0.3）

| 问题 | 状态 |
|------|------|
| 代码骨架只有部分实现 | 🟢 设计如此（团队补全）|
| Python 3.11+ 依赖 | 🟡 最低要求 |
| 没多语言 SDK 模板 | 🟢 下个版本 |
