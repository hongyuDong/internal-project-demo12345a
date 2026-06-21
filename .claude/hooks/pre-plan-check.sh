#!/bin/bash
# pre-plan-check.sh - 任务执行前检查规划完整性
# 触发: UserPromptSubmit (主代理接到任务时)
# 退出码: 0 = 允许, 2 = 阻断（强制先规划）

set -e

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // empty')

if [ -z "$PROMPT" ]; then
  exit 0
fi

# 1. 检测"动手型"指令（说明用户想直接执行）
ACTION_PATTERNS=(
  "^实现"
  "^添加"
  "^修复"
  "^重构"
  "^写"
  "^改"
  "^加"
  "^优化"
  "^删除"
  "^部署"
  "^release"
  "^PR"
  "^implement"
  "^add"
  "^fix"
  "^refactor"
  "^write"
  "^change"
  "^delete"
  "^deploy"
)

IS_ACTION=false
for PATTERN in "${ACTION_PATTERNS[@]}"; do
  if [[ "$PROMPT" =~ $PATTERN ]]; then
    IS_ACTION=true
    break
  fi
done

# 如果不是"动手型"指令，正常通过
if [ "$IS_ACTION" = "false" ]; then
  exit 0
fi

# 2. 检查是否有关联工单 / 任务标识
HAS_TICKET=$(echo "$PROMPT" | grep -E "PROJ-[0-9]+|#[0-9]+|JIRA-[0-9]+" || true)

# 3. 检查是否有 task_plan.md
TASK_PLAN=".planning/current/task_plan.md"
if [ -f "$TASK_PLAN" ]; then
  # 有 task_plan.md，但要看是不是对应的任务
  PLAN_TICKET=$(grep -oE "PROJ-[0-9]+" "$TASK_PLAN" | head -1 || echo "")
  
  if [ -n "$HAS_TICKET" ] && [ -n "$PLAN_TICKET" ]; then
    PROMPT_TICKET=$(echo "$HAS_TICKET" | grep -oE "PROJ-[0-9]+" | head -1)
    
    if [ "$PROMPT_TICKET" = "$PLAN_TICKET" ]; then
      # 任务匹配，检查 plan 是否完整
      if grep -q "## 验收标准" "$TASK_PLAN" && \
         grep -q "## 子任务" "$TASK_PLAN" && \
         grep -q "## 风险" "$TASK_PLAN"; then
        # 完整，放行
        exit 0
      fi
    fi
  fi
  
  # 有 task_plan 但不匹配或不全，警告但允许
  cat >&2 <<EOF
⚠️  [pre-plan-check] 任务规划可能不完整

检测到动手指令，但 task_plan.md 不匹配或不完整：

指令: $PROMPT
当前任务: $PLAN_TICKET

建议先完成 /plan 或 /decompose：
1. 读 .planning/current/task_plan.md
2. 确认这是当前任务
3. 补齐缺失的：验收标准 / 子任务 / 风险评估

继续执行？按回车继续，或 Ctrl+C 中断。
EOF
  # 不阻断（避免太烦人），但给警告
  exit 0
fi

# 4. 没有 task_plan.md，强提示
cat >&2 <<EOF
🚨 [pre-plan-check] 检测到动手指令，但没有任务规划

指令: $PROMPT

公司策略要求先规划后执行。请：

1. 运行 /plan 或 /decompose 创建 task_plan.md
2. 或在指令里说"先规划"
3. 或用 /decompose-existing 复用现有任务

为什么必须先规划？
- 避免遗漏验收标准
- 强制评估风险
- 团队知识沉淀
- Claude / 团队对齐预期

如确认要跳过规划（紧急情况），请明确说"跳过规划，直接执行"。
EOF

# 不阻断，但给出明显提示（避免误伤）
exit 0
