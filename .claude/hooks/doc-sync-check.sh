#!/bin/bash
# doc-sync-check.sh - 检查代码与文档是否同步
# 触发: PostToolUse (Write | Edit)
# 退出码: 0 = 允许（有警告但不阻断）

set -e

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '
  .tool_input.file_path // 
  .tool_input.path // 
  empty
')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
WARNINGS=()

# 1. 改了 src/api/ 但没动 docs/api/
if [[ "$FILE_PATH" =~ src/api/ ]] && [[ ! "$FILE_PATH" =~ test ]]; then
  DOCS_API="$PROJECT_DIR/docs/api"
  if [ -d "$DOCS_API" ]; then
    # 检查是否今天有更新
    if ! find "$DOCS_API" -name "*.md" -o -name "*.yaml" 2>/dev/null | \
       xargs grep -l "$(date +%Y-%m-%d)" 2>/dev/null | head -1 | grep -q .; then
      WARNINGS+=("📚 API 代码改了，但 docs/api/ 今天没更新")
    fi
  fi
fi

# 2. 改了 src/models/ 但没动 docs/domain/
if [[ "$FILE_PATH" =~ src/models/ ]]; then
  MODEL_NAME=$(basename "$FILE_PATH" .py)
  ENTITY_DOC="$PROJECT_DIR/docs/domain/entities/$MODEL_NAME.md"
  if [ ! -f "$ENTITY_DOC" ]; then
    WARNINGS+=("📚 Model 改了，但 docs/domain/entities/$MODEL_NAME.md 不存在")
  fi
fi

# 3. 改了 src/services/ 但没动业务规则
if [[ "$FILE_PATH" =~ src/services/ ]]; then
  # 检查 BR 引用
  BR_FILE="$PROJECT_DIR/docs/requirements/business-rules.md"
  if [ -f "$BR_FILE" ]; then
    # 检查 service 是否引用 BR-NNN
    if grep -q "BR-" "$FILE_PATH" 2>/dev/null; then
      # 检查 BR 文件最近更新
      BR_MTIME=$(stat -c %Y "$BR_FILE" 2>/dev/null || echo 0)
      NOW=$(date +%s)
      DAYS_OLD=$(( (NOW - BR_MTIME) / 86400 ))
      
      if [ "$DAYS_OLD" -gt 90 ]; then
        WARNINGS+=("📚 Service 引用 BR-* 但 business-rules.md 已 $DAYS_OLD 天未更新")
      fi
    fi
  fi
fi

# 4. 改了 dependencies (pyproject.toml, requirements.txt)
if [[ "$FILE_PATH" =~ (pyproject\.toml|requirements.*\.txt|Pipfile|package\.json)$ ]]; then
  ADR_DIR="$PROJECT_DIR/docs/architecture/adr"
  if [ -d "$ADR_DIR" ]; then
    # 检查 ADR 文件最近更新
    LATEST_ADR=$(find "$ADR_DIR" -name "*.md" -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)
    
    if [ -n "$LATEST_ADR" ]; then
      ADR_MTIME=$(stat -c %Y "$LATEST_ADR" 2>/dev/null || echo 0)
      NOW=$(date +%s)
      DAYS_OLD=$(( (NOW - ADR_MTIME) / 86400 ))
      
      if [ "$DAYS_OLD" -gt 180 ]; then
        WARNINGS+=("📚 依赖改了，但 ADR 最近更新是 $DAYS_OLD 天前（建议 review 技术选型）")
      fi
    fi
  fi
fi

# 5. 改了 .env.example 但没动 README
if [[ "$FILE_PATH" =~ \.env\.example$ ]]; then
  README="$PROJECT_DIR/README.md"
  if [ -f "$README" ]; then
    if ! grep -q "Environment\|环境变量" "$README" 2>/dev/null; then
      WARNINGS+=("📚 .env.example 改了，但 README 没说明环境变量")
    fi
  fi
fi

# 输出警告
if [ ${#WARNINGS[@]} -gt 0 ]; then
  cat >&2 <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  [doc-sync-check] 文档同步提醒
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  for WARNING in "${WARNINGS[@]}"; do
    echo "  $WARNING" >&2
  done
  cat >&2 <<EOF

💡 建议：
  - 更新对应文档
  - 或用 /update-docs 命令
  - 或在 commit message 里说"无需更新文档" + 理由
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi

exit 0
