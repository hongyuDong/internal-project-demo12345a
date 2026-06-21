#!/bin/bash
# post-task-update.sh - 任务执行后自动更新进度文件
# 触发: PostToolUse (* - 所有工具)
# 退出码: 0 = 总是成功

set -e

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TIME_CN=$(date "+%Y-%m-%d %H:%M")

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TASK_PLAN="$PROJECT_DIR/.planning/current/task_plan.md"
PROGRESS="$PROJECT_DIR/.planning/current/progress.md"
NOTES="$PROJECT_DIR/.planning/current/notes.md"

# 1. 只在写文件类工具时做特殊处理
if [[ "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '
    .tool_input.file_path // 
    .tool_input.path // 
    empty
  ')
  
  if [ -z "$FILE_PATH" ]; then
    exit 0
  fi
  
  # 检查是否是源代码改动（src/ 下的）
  if [[ "$FILE_PATH" =~ /src/ ]]; then
    # 是代码改动，更新 progress.md 的"代码变更"段
    mkdir -p "$(dirname "$PROGRESS")"
    touch "$PROGRESS"
    
    # 检查是否已经记录了这次变更（避免重复）
    LAST_LINE=$(tail -1 "$PROGRESS" 2>/dev/null || echo "")
    if [[ "$LAST_LINE" != *"$FILE_PATH"* ]] || [[ "$LAST_LINE" != *"$TIMESTAMP"* ]]; then
      cat >> "$PROGRESS" <<EOF

### $TIME_CN — 代码变更
- **文件**: \`$FILE_PATH\`
- **工具**: $TOOL_NAME
- **时间**: $TIMESTAMP
EOF
    fi
  fi
fi

# 2. 检测是否完成任务（特定 tool 触发）
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  
  # 检测"完成任务"信号
  if [[ "$COMMAND" =~ (git commit|gh pr create|npm run build|pytest|make test) ]]; then
    if [ -f "$PROGRESS" ]; then
      cat >> "$PROGRESS" <<EOF

### $TIME_CN — 任务信号
- **动作**: $COMMAND
- **状态**: 可能完成某个 subtask
- **建议**: 检查 task_plan.md，更新对应复选框
EOF
    fi
  fi
fi

# 3. 提醒文档同步（如果改了代码但没改文档）
if [[ "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  
  # 改了 API 但没更新 API 文档
  if [[ "$FILE_PATH" =~ src/api/ ]] && [[ ! "$FILE_PATH" =~ test ]]; then
    if [ ! -f "$PROJECT_DIR/docs/api/changelog.md" ] || \
       ! grep -q "$(date +%Y-%m-%d)" "$PROJECT_DIR/docs/api/changelog.md" 2>/dev/null; then
      cat >&2 <<EOF
💡 [post-task-update] 提醒：API 变更需更新文档

你改了: $FILE_PATH

记得同步更新：
- docs/api/openapi.yaml（如改了 endpoint）
- docs/api/changelog.md
- docs/project/changelog.md（项目级）

或者用 /update-api-docs 命令
EOF
    fi
  fi
  
  # 改了 model 但没更新 domain 文档
  if [[ "$FILE_PATH" =~ src/models/ ]]; then
    if [ -d "$PROJECT_DIR/docs/domain/entities" ]; then
      MODEL_NAME=$(basename "$FILE_PATH" .py)
      ENTITY_DOC="$PROJECT_DIR/docs/domain/entities/$MODEL_NAME.md"
      if [ ! -f "$ENTITY_DOC" ]; then
        cat >&2 <<EOF
💡 [post-task-update] 提醒：实体变更需更新文档

你改了 model: $FILE_PATH

建议创建/更新：docs/domain/entities/$MODEL_NAME.md
模板见 docs/domain/entities/user.md
EOF
      fi
    fi
  fi
fi

# 4. 计算并报告进度（如有 task_plan.md）
if [ -f "$TASK_PLAN" ]; then
  TOTAL=$(grep -c "^- \[" "$TASK_PLAN" 2>/dev/null || echo 0)
  DONE=$(grep -c "^- \[x\]" "$TASK_PLAN" 2>/dev/null || echo 0)
  
  if [ "$TOTAL" -gt 0 ]; then
    PCT=$((DONE * 100 / TOTAL))
    
    # 只在进度变化时报告
    LAST_PCT_FILE="/tmp/.claude_last_pct"
    LAST_PCT=$(cat "$LAST_PCT_FILE" 2>/dev/null || echo "0")
    
    if [ "$PCT" != "$LAST_PCT" ]; then
      echo "$PCT" > "$LAST_PCT_FILE"
      
      # 只在里程碑变化时通知（每 25%）
      if (( PCT % 25 == 0 )) && [ "$PCT" != "0" ]; then
        cat >&2 <<EOF

📊 [progress] 任务进度: $DONE/$TOTAL ($PCT%)
EOF
      fi
    fi
  fi
fi

exit 0
