#!/bin/bash
# ============================================================
#  Claude Code 企业模板 - macOS/Linux 一键安装
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo
echo "============================================================"
echo -e "  ${BLUE}Claude Code Enterprise Template - Installer${NC}"
echo "============================================================"
echo

# 检查 Claude Code
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}[WARN]${NC} 未检测到 claude 命令"
    echo "        请先安装: https://claude.com/install"
    echo
    read -p "        继续? [y/N]: " CONTINUE
    if [ "${CONTINUE}" != "y" ] && [ "${CONTINUE}" != "Y" ]; then
        exit 1
    fi
fi

# 选择模式
echo "请选择安装模式:"
echo
echo "  [1] 项目级安装 (推荐)"
echo "  [2] 全局安装"
echo "  [3] 模板项目"
echo "  [0] 退出"
echo
read -p "  选择 [1/2/3/0]: " MODE

case "$MODE" in
    1) install_project ;;
    2) install_global ;;
    3) install_template ;;
    0) exit 0 ;;
    *) echo -e "${RED}无效选择${NC}"; exit 1 ;;
esac

install_project() {
    echo
    read -p "  目标项目路径 (如 /home/user/projects/my-app): " TARGET
    [ -z "$TARGET" ] && { echo -e "${RED}路径无效${NC}"; exit 1; }
    
    TARGET="${TARGET%/}"
    mkdir -p "$TARGET"
    
    if [ -d "$TARGET/.claude" ]; then
        read -p "  已存在 .claude/, 覆盖? [y/N]: " OVERWRITE
        [ "${OVERWRITE}" != "y" ] && [ "${OVERWRITE}" != "Y" ] && exit 0
        mv "$TARGET/.claude" "$TARGET/.claude.bak"
    fi
    
    echo -e "${GREEN}[OK]${NC} 复制 .claude/ ..."
    cp -r "$SCRIPT_DIR/.claude" "$TARGET/.claude"
    chmod +x "$TARGET/.claude/hooks/"*.sh
    
    echo -e "${GREEN}[OK]${NC} 复制 CLAUDE.md ..."
    cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
    
    echo -e "${GREEN}[OK]${NC} 复制 docs/ ..."
    mkdir -p "$TARGET/docs"
    for d in requirements domain architecture project api runbook testing; do
        if [ -d "$SCRIPT_DIR/docs/$d" ]; then
            mkdir -p "$TARGET/docs/$d"
            cp -r "$SCRIPT_DIR/docs/$d/"* "$TARGET/docs/$d/"
        fi
    done
    # diagrams
    if [ -d "$SCRIPT_DIR/docs/architecture/diagrams" ]; then
        mkdir -p "$TARGET/docs/architecture/diagrams"
        cp -r "$SCRIPT_DIR/docs/architecture/diagrams/"* "$TARGET/docs/architecture/diagrams/"
    fi
    
    echo -e "${GREEN}[OK]${NC} 复制 .planning/ ..."
    mkdir -p "$TARGET/.planning"
    cp -r "$SCRIPT_DIR/.planning/"* "$TARGET/.planning/"
    
    cp "$SCRIPT_DIR/README.md" "$TARGET/CLAUDE-TEMPLATE-README.md"
    
    echo
    echo "============================================================"
    echo -e "  ${GREEN}[OK] 项目级安装成功!${NC}"
    echo "============================================================"
    echo
    echo "  位置: $TARGET"
    echo
    echo "下一步:"
    echo "  cd $TARGET"
    echo "  编辑 CLAUDE.md"
    echo "  claude  启动 Claude Code"
}

install_global() {
    GLOBAL_DIR="$HOME/.claude"
    echo
    echo "  全局目录: $GLOBAL_DIR"
    
    mkdir -p "$GLOBAL_DIR/agents" "$GLOBAL_DIR/skills" "$GLOBAL_DIR/commands"
    
    echo -e "${GREEN}[OK]${NC} 复制 agents/ ..."
    cp -r "$SCRIPT_DIR/.claude/agents/"* "$GLOBAL_DIR/agents/"
    
    echo -e "${GREEN}[OK]${NC} 复制 skills/ ..."
    cp -r "$SCRIPT_DIR/.claude/skills/"* "$GLOBAL_DIR/skills/"
    
    echo -e "${GREEN}[OK]${NC} 复制 commands/ ..."
    cp -r "$SCRIPT_DIR/.claude/commands/"* "$GLOBAL_DIR/commands/"
    
    echo
    echo "============================================================"
    echo -e "  ${GREEN}[OK] 全局安装成功!${NC}"
    echo "============================================================"
}

install_template() {
    echo
    read -p "  新项目路径: " NEW_DIR
    [ -z "$NEW_DIR" ] && exit 1
    
    NEW_DIR="${NEW_DIR%/}"
    mkdir -p "$NEW_DIR"
    
    # 复制整个项目（排除 install 脚本）
    cp -r "$SCRIPT_DIR/"* "$NEW_DIR/"
    rm -f "$NEW_DIR/install.bat" "$NEW_DIR/install.sh"
    rm -f "$NEW_DIR/uninstall.bat"
    rm -f "$NEW_DIR/run-debug.bat"
    
    echo
    echo "============================================================"
    echo -e "  ${GREEN}[OK] 模板项目创建成功!${NC}"
    echo "============================================================"
    echo
    echo "  位置: $NEW_DIR"
}

echo
