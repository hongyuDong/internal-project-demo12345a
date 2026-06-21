#!/bin/bash
# ============================================================
#  Claude Code 企业模板 - 版本发布脚本
#  Usage: ./release.sh v1.1
# ============================================================

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# === 参数 ===
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    # 读当前版本
    CURRENT=$(grep "Version" README.md | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+" | head -1)
    if [ -z "$CURRENT" ]; then
        CURRENT="v0.0.0"
    fi
    echo -e "${BLUE}当前版本:${NC} $CURRENT"
    echo -e "${BLUE}新版本:${NC} ?"
    read -p "       输入新版本号 [如 v1.1.0]: " VERSION
fi

if [ -z "$VERSION" ]; then
    echo -e "${RED}[ERROR]${NC} 版本号不能为空"
    exit 1
fi

# 校验格式
if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}[ERROR]${NC} 版本号格式错误（应为 vX.Y.Z）"
    exit 1
fi

echo
echo "============================================================"
echo -e "  ${BLUE}发布版本: $VERSION${NC}"
echo "============================================================"
echo

# === 1. 预检查 ===
echo -e "${BLUE}[1/5]${NC} 预检查..."

# 在 main 或 master 分支
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
    echo -e "${RED}[ERROR]${NC} 当前在 $BRANCH 分支，请切到 main 或 master"
    echo -e "       提示: 如果用其他分支名（如 develop），加 --branch 参数"
    exit 1
fi

# 工作区干净
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${RED}[ERROR]${NC} 工作区有未提交修改"
    git status --short
    exit 1
fi

# 与远端同步
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/$BRANCH 2>/dev/null || echo "")
if [ "$LOCAL" != "$REMOTE" ]; then
    echo -e "${RED}[ERROR]${NC} 本地与远端不同步"
    exit 1
fi

echo -e "       ${GREEN}[OK]${NC} 所有检查通过"
echo

# === 2. 更新版本号 ===
echo -e "${BLUE}[2/5]${NC} 更新版本号..."

# 在 README.md 和 INSTALL.md 中替换
for f in README.md INSTALL.md DELIVERY.md; do
    if [ -f "$f" ]; then
        sed -i.bak "s/Version.*v[0-9]\+\.[0-9]\+\.[0-9]\+/Version: $VERSION/g" "$f"
        sed -i.bak "s/版本.*v[0-9]\+\.[0-9]\+\.[0-9]\+/**版本**: $VERSION/g" "$f"
        rm -f "$f.bak"
    fi
done

# 加入 CHANGELOG
DATE=$(date +%Y-%m-%d)
if [ ! -f CHANGELOG.md ]; then
    cat > CHANGELOG.md <<EOF
# Changelog

## [$VERSION] - $DATE

### Added
- Initial release
EOF
fi

echo -e "       ${GREEN}[OK]${NC} 版本号更新到 $VERSION"
echo

# === 3. 提交 + tag ===
echo -e "${BLUE}[3/5]${NC} 提交 + tag..."

git add .
git diff --cached --quiet || {
    git commit -m "chore(release): $VERSION"
}

git tag -a "$VERSION" -m "Release $VERSION"

echo -e "       ${GREEN}[OK]${NC} Tag 创建: $VERSION"
echo

# === 4. 推送 ===
echo -e "${BLUE}[4/5]${NC} 推送..."

git push origin "$BRANCH"
git push origin "$VERSION"

echo -e "       ${GREEN}[OK]${NC} 推送完成"
echo

# === 5. 创建 GitHub Release ===
echo -e "${BLUE}[5/5]${NC} 创建 GitHub Release..."

if command -v gh &> /dev/null; then
    read -p "       用 gh CLI 创建 Release? [Y/n]: " USE_GH
    if [ "${USE_GH}" != "n" ] && [ "${USE_GH}" != "N" ]; then
        gh release create "$VERSION" \
            --title "$VERSION" \
            --notes "## What's Changed

- See CHANGELOG.md for details

## Assets

- Source code (zip)
- Source code (tar.gz)
" \
            --target "$BRANCH"
        echo -e "       ${GREEN}[OK]${NC} Release 创建: https://github.com/$(git remote get-url origin | sed 's/.*://;s/.git$//')/releases/tag/$VERSION"
    fi
else
    echo -e "       ${YELLOW}[INFO]${NC} 手动创建 Release:"
    echo "       https://github.com/$(git remote get-url origin | sed 's/.*://;s/.git$//')/releases/new"
    echo "       Tag: $VERSION"
fi

echo
echo "============================================================"
echo -e "  ${GREEN}[OK] 发布完成: $VERSION${NC}"
echo "============================================================"
echo
echo "下一步:"
echo "  1. 团队通知 Slack #announcements"
echo "  2. 更新内部 wiki"
echo "  3. 收集反馈（GitHub Issues / Slack）"
echo
