#!/bin/bash
# ============================================================
#  Claude Code 企业模板 - Git 推送脚本 (macOS / Linux)
#  Usage: ./init-git.sh
# ============================================================

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo
echo "============================================================"
echo -e "  ${BLUE}Claude Code Enterprise Template - Git Setup${NC}"
echo "============================================================"
echo

# === 1. 前置检查 ===
echo -e "${BLUE}[1/7]${NC} 检查环境..."

# git
if ! command -v git &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} git 未安装"
    echo "        安装: brew install git  /  apt install git"
    exit 1
fi
echo -e "       ${GREEN}[OK]${NC} git: $(git --version)"

# gh (GitHub CLI，可选)
HAS_GH=false
if command -v gh &> /dev/null; then
    HAS_GH=true
    echo -e "       ${GREEN}[OK]${NC} gh:  $(gh --version | head -1)"
else
    echo -e "       ${YELLOW}[WARN]${NC} gh CLI 未安装（可选，用于自动创建 GitHub 仓库）"
    echo -e "              安装: brew install gh  /  https://cli.github.com"
fi

# ssh-key 检查
if [ ! -f "$HOME/.ssh/id_rsa.pub" ] && [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
    echo -e "       ${YELLOW}[WARN]${NC} 未找到 SSH 公钥（推送可能需要）"
fi

echo

# === 2. 仓库配置 ===
echo -e "${BLUE}[2/7]${NC} 仓库配置..."

read -p "       GitHub 用户名/组织 (默认: company): " GITHUB_OWNER
GITHUB_OWNER=${GITHUB_OWNER:-company}

read -p "       仓库名 (默认: claude-code-template): " REPO_NAME
REPO_NAME=${REPO_NAME:-claude-code-template}

read -p "       仓库可见性 [public/private] (默认: private): " VISIBILITY
VISIBILITY=${VISIBILITY:-private}

read -p "       远程协议 [ssh/https] (默认: ssh): " PROTOCOL
PROTOCOL=${PROTOCOL:-ssh}

if [ "$PROTOCOL" = "ssh" ]; then
    REMOTE_URL="git@github.com:${GITHUB_OWNER}/${REPO_NAME}.git"
else
    REMOTE_URL="https://github.com/${GITHUB_OWNER}/${REPO_NAME}.git"
fi

echo -e "       ${GREEN}目标仓库${NC}: $REMOTE_URL"
echo -e "       ${GREEN}可见性${NC}:   $VISIBILITY"
echo

# === 3. 安全检查（关键）===
echo -e "${BLUE}[3/7]${NC} 安全检查..."

# 检查是否有密钥泄漏
echo "       扫描密钥泄漏..."
SECRETS_FOUND=0

# .env / .key / .pem
find . -type f \( -name "*.key" -o -name "*.pem" -o -name ".env" -o -name "id_rsa*" \) \
    ! -path "./.git/*" ! -path "./docs/*" 2>/dev/null | while read f; do
    echo -e "       ${RED}[WARN]${NC} 发现密钥文件: $f"
done

# grep AWS key / GitHub token
if grep -rE "AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}" . --include="*.md" --include="*.yaml" --include="*.json" 2>/dev/null | grep -v ".git/" | head -3; then
    echo -e "       ${RED}[WARN]${NC} 发现 AWS/GitHub key 模式（可能是示例，请确认）"
fi

# git status
if git status --short 2>/dev/null | grep -E "\.env$|\.key$|id_rsa"; then
    echo -e "       ${RED}[ERROR]${NC} .gitignore 漏掉了密钥文件！请先修复"
    exit 1
fi

echo -e "       ${GREEN}[OK]${NC} 未发现密钥泄漏"
echo

# === 4. git init ===
echo -e "${BLUE}[4/7]${NC} 初始化 Git 仓库..."

if [ -d .git ]; then
    echo -e "       ${YELLOW}[INFO]${NC} .git 已存在，跳过 init"
else
    git init
    git checkout -b main 2>/dev/null || git branch -m main
    echo -e "       ${GREEN}[OK]${NC} git init 完成（分支: main）"
fi

# 配置 git 用户
if [ -z "$(git config user.name)" ]; then
    read -p "       git user.name: " GIT_NAME
    git config user.name "$GIT_NAME"
fi
if [ -z "$(git config user.email)" ]; then
    read -p "       git user.email: " GIT_EMAIL
    git config user.email "$GIT_EMAIL"
fi

echo

# === 5. 首次提交 ===
echo -e "${BLUE}[5/7]${NC} 首次提交..."

git add .
git status --short | head -10
echo "       ..."
echo "       总文件: $(git status --short | wc -l)"

echo
read -p "       确认提交? [Y/n]: " CONFIRM
if [ "${CONFIRM}" != "Y" ] && [ "${CONFIRM}" != "y" ] && [ -n "$CONFIRM" ]; then
    echo -e "       ${YELLOW}[INFO]${NC} 已取消"
    exit 0
fi

git commit -m "$(cat <<EOF
feat: initial release v1.0

- 86 files / 644 KB Claude Code enterprise template
- 8 sub-agents (product-owner, architect, planner, tracker, ...)
- 7 skills (decompose, plan, update-progress, ...)
- 8 hooks (security + audit + format + plan-check + ...)
- 20 OpenAPI 3.1 endpoints
- 18 business rules (BR-001~018)
- 4 architecture decision records (ADR-0001, 0002, 0003, 0005)
- 10 incident runbooks
- Complete test strategy (unit/integration/e2e/load)
- Windows installer (install.bat + uninstall.bat)

See README.md for details.
EOF
)"

echo -e "       ${GREEN}[OK]${NC} 提交完成: $(git rev-parse --short HEAD)"
echo

# === 6. 创建 GitHub 仓库 ===
echo -e "${BLUE}[6/7]${NC} 创建 GitHub 仓库..."

if [ "$HAS_GH" = true ]; then
    read -p "       用 gh CLI 创建? [Y/n]: " USE_GH
    if [ "${USE_GH}" != "n" ] && [ "${USE_GH}" != "N" ]; then
        if gh repo view "$GITHUB_OWNER/$REPO_NAME" &>/dev/null; then
            echo -e "       ${YELLOW}[INFO]${NC} 仓库已存在: $GITHUB_OWNER/$REPO_NAME"
        else
            gh repo create "$GITHUB_OWNER/$REPO_NAME" \
                --"$VISIBILITY" \
                --description "Claude Code Enterprise Template - 安全沙箱 + 业务上下文 + 规划系统 + 进度跟踪的一站式配置" \
                --source=. \
                --remote=origin \
                --push
            echo -e "       ${GREEN}[OK]${NC} GitHub 仓库创建并推送成功"
        fi
    fi
else
    echo -e "       ${YELLOW}[INFO]${NC} 请手动创建仓库:"
    echo "       https://github.com/new"
    echo "       Name: $REPO_NAME"
    echo "       Visibility: $VISIBILITY"
    echo "       (其他选项默认即可)"
    echo
    read -p "       创建好后按回车继续..." DUMMY
fi

# === 7. 推送 ===
echo -e "${BLUE}[7/7]${NC} 推送到 GitHub..."

# 添加 remote（如果还没有）
if ! git remote get-url origin &>/dev/null; then
    git remote add origin "$REMOTE_URL"
    echo -e "       添加 remote: $REMOTE_URL"
fi

git push -u origin main

if [ $? -eq 0 ]; then
    echo
    echo "============================================================"
    echo -e "  ${GREEN}[OK] 推送成功!${NC}"
    echo "============================================================"
    echo
    echo "  仓库: https://github.com/$GITHUB_OWNER/$REPO_NAME"
    echo "  分支: main"
    echo "  提交: $(git rev-parse --short HEAD)"
    echo "  文件: $(git ls-files | wc -l | tr -d ' ')"
    echo
    echo "下一步:"
    echo "  1. 团队成员: git clone $REMOTE_URL"
    echo "  2. 进入项目: cd $REPO_NAME && claude"
    echo "  3. 阅读 README.md 了解用法"
    echo "  4. 发布版本: ./release.sh"
    echo
else
    echo -e "       ${RED}[ERROR]${NC} 推送失败"
    echo "       常见原因:"
    echo "       1. 没有推送权限 → 检查 SSH key / PAT"
    echo "       2. 仓库不存在 → 先在 GitHub 创建"
    echo "       3. 网络问题"
    exit 1
fi
