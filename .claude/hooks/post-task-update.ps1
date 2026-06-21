# post-task-update.ps1 - 任务执行后自动更新进度文件
# 触发: PostToolUse (* - 所有工具)
# 退出码: 0 = 总是成功

$ErrorActionPreference = 'SilentlyContinue'

$input = $input | Out-String
if ([string]::IsNullOrWhiteSpace($input)) { exit 0 }

try {
    $data = $input | ConvertFrom-Json -ErrorAction SilentlyContinue
} catch {
    exit 0
}

$toolName = $data.tool_name
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$timeCN = Get-Date -Format "yyyy-MM-dd HH:mm"
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }

$progressPath = Join-Path $projectDir ".planning/current/progress.md"
$taskPlanPath = Join-Path $projectDir ".planning/current/task_plan.md"

# 1. 写文件类工具时记录
if ($toolName -in @('Write', 'Edit', 'MultiEdit')) {
    $toolInput = $data.tool_input
    if ($toolInput.PSObject.Properties['file_path']) {
        $filePath = $toolInput.file_path
        
        # src/ 下的代码改动
        if ($filePath -match '/src/') {
            $progressDir = Split-Path $progressPath -Parent
            if (-not (Test-Path $progressDir)) {
                New-Item -ItemType Directory -Path $progressDir -Force | Out-Null
            }
            if (-not (Test-Path $progressPath)) {
                New-Item -ItemType File -Path $progressPath -Force | Out-Null
            }
            
            $entry = @"

### $timeCN — 代码变更
- **文件**: ``$filePath``
- **工具**: $toolName
- **时间**: $timestamp
"@
            Add-Content -Path $progressPath -Value $entry -Encoding UTF8
        }
        
        # 改 API 但没更新文档
        if ($filePath -match 'src/api/' -and $filePath -notmatch 'test') {
            $changelogPath = Join-Path $projectDir "docs/api/changelog.md"
            if (Test-Path $changelogPath) {
                $today = Get-Date -Format "yyyy-MM-dd"
                $content = Get-Content $changelogPath -Raw -ErrorAction SilentlyContinue
                if ($content -notmatch $today) {
                    [Console]::Error.WriteLine @"

💡 [post-task-update] 提醒: API 变更需更新文档

你改了: $filePath

记得同步:
- docs/api/openapi.yaml
- docs/api/changelog.md
- docs/project/changelog.md
"@
                }
            }
        }
    }
}

# 2. 计算进度
if (Test-Path $taskPlanPath) {
    try {
        $planContent = Get-Content $taskPlanPath -Raw -ErrorAction SilentlyContinue
        $total = ([regex]::Matches($planContent, '^- \[ ', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
        $done = ([regex]::Matches($planContent, '^- \[x\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
        
        if ($total -gt 0) {
            $pct = [math]::Floor(($done * 100) / $total)
            if ($pct % 25 -eq 0 -and $pct -ne 0) {
                [Console]::Error.WriteLine "`n📊 [progress] 任务进度: $done/$total ($pct%)"
            }
        }
    } catch {}
}

exit 0
