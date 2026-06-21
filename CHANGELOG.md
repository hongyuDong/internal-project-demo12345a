# Changelog

---

## [1.0.2] - 2026-06-21

### 🔧 Fixed

- ✅ **补 ADR-0004（PII 加密策略）** — 不再跳号
- ✅ **PowerShell 版 hooks**（.ps1）— Windows 用户友好
- ✅ **post-task-update.sh 不再用 /tmp** — 跨平台（用 `.planning/.cache/`）
- ✅ **release.sh 兼容 main/master** — 不强制 main
- ✅ **`.planning/.cache/` 加到 .gitignore**

### ✨ Added

- ✅ **`.editorconfig`** — 跨编辑器一致（缩进/EOL/编码）
- ✅ **`.gitattributes`** — 行尾控制 + merge 策略
- ✅ **`.planning/current/` 真实示例**：
  - `task_plan.md` — 完整 PROJ-1001 任务计划
  - `notes.md` — profile 数据 + 失败尝试
  - `progress.md` — 50% 进度 + 时间线
- ✅ **PowerShell hooks**（3 个）：
  - `secret-scanner.ps1` — Windows 版密钥扫描
  - `pre-plan-check.ps1` — Windows 版任务前检查
  - `post-task-update.ps1` — Windows 版进度更新

### 📊 Statistics

- **Files**: 95 → **102** (+7)
- **Hooks**: 8 .sh + 3 .ps1 = **11 hooks**（跨平台）
- **ADRs**: 4 → **5**（补完）

---

## [1.0.1] - 2026-06-21

### 🔧 Fixed（基于自我 Review）

- 修复 README 目录树与源目录不一致
- 重写 README.md（17 KB → 8.7 KB）
- 新增 `install.sh`（macOS/Linux 安装脚本）
- 简化 install.bat 复制逻辑

### ✨ Added

- GitHub Actions CI/CD（`.github/workflows/`）
- Issue 模板（bug_report + feature_request）
- OpenAPI 代码生成脚本
- 完整 `.gitignore`
- 完整发布流程（init-git + release）
- `run-debug.bat` 调试运行器（后被 init-git.bat 替代，已删）

---

## [1.0.0] - 2026-06-21

### 🎉 Initial Release

86 文件 / 644 KB 完整 Claude Code 企业模板

---

## ⚠️ 已知问题（v1.0.2）

| 问题 | 状态 |
|------|------|
| `.sh` hooks 在 Windows 不能直接跑 | 🟢 已加 `.ps1` 版本 |
| 没 Pydantic 模型 | 🟢 设计如此（这是模板）|
| PowerShell hooks 需要 ExecutionPolicy | 🟡 文档说明 |
