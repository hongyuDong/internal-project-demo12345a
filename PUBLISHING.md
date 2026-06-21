# Git 发布指南

> 一键把 internal-project 推到公司 GitHub

---

## 🚀 首次发布（init-git）

### Windows

双击 `init-git.bat`，按提示输入：

```
============================================================
  Claude Code Enterprise Template - Git Setup
============================================================

[1/7] 检查环境...
       [OK] git: git version 2.43.0
       [WARN] gh CLI 未安装（可选）

[2/7] 仓库配置...
       GitHub 用户名/组织 (默认: company): my-company
       仓库名 (默认: claude-code-template): claude-code-template
       可见性 [public/private] (默认: private): private
       协议 [ssh/https] (默认: ssh): ssh

       目标: git@github.com:my-company/claude-code-template.git
       可见性: private

[3/7] 安全检查...
       [OK] 安全检查通过

[4/7] 初始化 Git...
       [OK] git init
       git user.name: 张三
       git user.email: zhangsan@company.com

[5/7] 首次提交...
       总文件: 90
       确认提交? [Y/n]: Y
       [OK] 提交完成

[6/7] 创建 GitHub 仓库...
       (手动创建 https://github.com/new)
       创建好后按回车继续:

[7/7] 推送到 GitHub...
       [OK] 推送成功!

============================================================
  [OK] 推送成功!
============================================================
```

### macOS / Linux

```bash
chmod +x init-git.sh release.sh
./init-git.sh
```

---

## 📦 后续版本发布

### Windows

```batch
release.bat v1.1.0
```

### macOS / Linux

```bash
./release.sh v1.1.0
```

**自动完成**：

```
[1/5] 预检查...
       [OK] 检查通过

[2/5] 更新版本号...
       [OK] 版本号: v1.1.0

[3/5] 提交 + tag...
       [OK] Tag: v1.1.0

[4/5] 推送...
       [OK] 推送完成

[5/5] 创建 GitHub Release...
       [OK] Release 创建: https://github.com/my-company/claude-code-template/releases/tag/v1.1.0

============================================================
  [OK] 发布完成: v1.1.0
============================================================
```

---

## 🔧 前置条件

| 工具 | 必需 | 安装 |
|------|------|------|
| **git** | ✅ | https://git-scm.com/downloads |
| **GitHub 账号** | ✅ | - |
| **gh CLI**（推荐） | ⭐ 自动创建仓库 | https://cli.github.com |
| **SSH key**（SSH 协议） | ✅ 已配 GitHub | https://docs.github.com/en/authentication/connecting-to-github-with-ssh |

---

## 🔐 安全设计

`init-git.sh` 自动做：

1. ✅ **密钥泄漏扫描**：检查 `.key` / `.pem` / `.env` / AWS / GitHub token 模式
2. ✅ **`.gitignore` 验证**：确保密钥不会被 `git add`
3. ✅ **分支检查**：默认 main（不是 master）
4. ✅ **可恢复**：失败不破坏现有 repo

---

## 📝 提交信息规范

`init-git.sh` 使用 **Conventional Commits**：

```
feat: initial release v1.0

feat(scope): description
^-- type: feat/fix/chore/docs/refactor/test/perf
```

**类型说明**：

| 类型 | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档 |
| `refactor` | 重构 |
| `test` | 测试 |
| `perf` | 性能 |
| `chore` | 杂项（如 release） |
| `ci` | CI/CD |

---

## 🔄 团队成员使用

```bash
# 1. 克隆
git clone git@github.com:my-company/claude-code-template.git

# 2. 进入
cd claude-code-template

# 3. 安装到目标项目（Windows）
#    双击 install.bat，选模式 1

# 4. 或手动安装（macOS / Linux）
cp -r .claude/* /path/to/project/.claude/
cp CLAUDE.md /path/to/project/
# ...

# 5. 修改 CLAUDE.md
code /path/to/project/CLAUDE.md

# 6. 启动 Claude Code
cd /path/to/project
claude
```

---

## 📋 版本管理

```
v1.0.0 (2026-06-21)  ← 当前
├─ 86 文件
├─ 8 hooks + 8 sub-agents + 7 skills
├─ 20 OpenAPI 端点
└─ 10 Runbooks

v1.1.0 (计划)
├─ + ER 图细节
├─ + 性能基线
└─ ...

v2.0.0 (2027 Q1)
├─ 重大重构
└─ ...
```

**SemVer 规则**：

- **MAJOR**：不兼容变更
- **MINOR**：向后兼容新功能
- **PATCH**：向后兼容 bug 修复

---

## 🔗 仓库结构

```
my-company/claude-code-template/
├── main                     ← 主分支
├── develop                  ← 开发分支（可选）
├── release/v1.1.0           ← 发布分支（短期）
└── feature/xxx              ← 功能分支（短期）
```

**推荐分支策略**（GitHub Flow）：

```
main       ← 生产可用
  ↑
  └─ feature/add-xxx       ← 开发分支
```

---

## 📞 故障排查

### Q: 推送失败 "permission denied"？

```bash
# 1. 检查 SSH 连接
ssh -T git@github.com

# 2. 检查 remote
git remote -v

# 3. 检查 token / SSH key
ssh-add -l
```

### Q: "gh repo create" 失败？

```bash
# 1. 检查登录
gh auth status

# 2. 重新登录
gh auth login

# 3. 检查权限（需要有 repo 创建权限）
```

### Q: 如何强制推送？

```bash
# ⚠️ 危险！只用于没有协作者的主分支
git push --force-with-lease origin main
```

### Q: 如何回滚版本？

```bash
# 1. 删除远端 tag
git push --delete origin v1.1.0

# 2. 删除本地 tag
git tag -d v1.1.0

# 3. 撤销 Release（GitHub UI 操作）
# 4. 回滚 commit（如需要）
git revert HEAD
```

---

## 📚 相关

- [README.md](README.md) - 项目说明
- [DELIVERY.md](../DELIVERY.md) - 交付报告
- [DISTRIBUTION.md](../DISTRIBUTION.md) - 分发说明
- [INSTALL.md](INSTALL.md) - 安装说明
- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [Conventional Commits](https://www.conventionalcommits.org/)
