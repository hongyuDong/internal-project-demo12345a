# pre-plan-check.ps1 - 任务执行前检查规划完整性
# 触发: UserPromptSubmit (主代理接到任务时)
# 退出码: 0 = 允许, 2 = 阻断（强制先规划）

$ErrorActionPreference = 'Stop'

$input = $input | Out-String
if ([string]::IsNullOrWhiteSpace($input)) { exit 0 }

try {
    $data = $input | ConvertFrom-Json -ErrorAction SilentlyContinue
} catch {
    exit 0
}

$prompt = $data.user_prompt
if ([string]::IsNullOrWhiteSpace($prompt)) { exit 0 }

# 1. 检测"动手型"指令
$actionPatterns = @(
    '^实现', '^添加', '^修复', '^重构', '^写', '^改', '^加', '^优化',
    '^删除', '^部署', '^release', '^PR',
    '^implement', '^add', '^fix', '^refactor', '^write', '^change',
    '^delete', '^deploy'
)

$isAction = $false
foreach ($pattern in $actionPatterns) {
    if ($prompt -match $pattern) {
        $isAction = $true
        break
    }
}

if (-not $isAction) { exit 0 }

# 2. 检查是否有关联工单
if ($prompt -match 'PROJ-[0-9]+|#[0-9]+|JIRA-[0-9]+') {
    # 有关联工单，正常
}

# 3. 检查是否有 task_plan.md
$taskPlan = Join-Path $PWD ".planning/current/task_plan.md"
if (Test-Path $taskPlan) {
    $content = Get-Content $taskPlan -Raw -ErrorAction SilentlyContinue
    
    if ($content -match '## 验收标准' -and
        $content -match '## 子任务' -and
        $content -match '## 风险') {
        # 完整规划，放行
        exit 0
    }
    
    [Console]::Error.WriteLine @"

⚠️  [pre-plan-check] 任务规划可能不完整

检测到动手指令，但 task_plan.md 不匹配或不完整：

指令: $prompt

建议先完成 /plan 或 /decompose:
1. 读 .planning/current/task_plan.md
2. 确认这是当前任务
3. 补齐缺失的：验收标准 / 子任务 / 风险评估

继续执行？按 Ctrl+C 中断，或回车继续。
"@
    exit 0
}

# 4. 没有 task_plan.md，警告
[Console]::Error.WriteLine @"

🚨 [pre-plan-check] 检测到动手指令，但没有任务规划

指令: $prompt

公司策略要求先规划后执行。请：

1. 运行 /plan 或 /decompose 创建 task_plan.md
2. 或在指令里说"先规划"
3. 或用 /decompose-existing 复用现有任务

为什么必须先规划？
- 避免遗漏验收标准
- 强制评估风险
- 团队知识沉淀

如确认要跳过规划（紧急情况），请明确说"跳过规划，直接执行"。
"@

exit 0
