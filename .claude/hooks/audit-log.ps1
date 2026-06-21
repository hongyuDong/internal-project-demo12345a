# audit-log.ps1 - 审计日志：所有工具调用送到中央日志
# 触发: PostToolUse (* - 所有工具)
# 退出码: 0 = 总是成功（不阻断 Claude）

$ErrorActionPreference = 'SilentlyContinue'

$input = $input | Out-String
if ([string]::IsNullOrWhiteSpace($input)) { exit 0 }

try {
    $data = $input | ConvertFrom-Json -ErrorAction SilentlyContinue
} catch {
    exit 0
}

$toolName = $data.tool_name
$sessionId = $data.session_id
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$timeCN = Get-Date -Format "yyyy-MM-dd HH:mm"
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$hostnameS = $env:COMPUTERNAME
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$project = Split-Path $projectDir -Leaf

try {
    $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
    $gitCommit = git rev-parse --short HEAD 2>$null
} catch {
    $gitBranch = "no-git"
    $gitCommit = "no-commit"
}

# 1. 本地备份
$logDir = Join-Path $HOME ".claude/logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = Join-Path $logDir ("audit-" + (Get-Date -Format "yyyy-MM-dd") + ".jsonl")

$logEntry = @{
    timestamp   = $timestamp
    user        = $user
    hostname    = $hostnameS
    project     = $project
    tool        = $toolName
    session_id  = $sessionId
    git = @{
        branch = $gitBranch
        commit = $gitCommit
    }
    input_size  = $input.Length
} | ConvertTo-Json -Compress

Add-Content -Path $logFile -Value $logEntry -Encoding UTF8

# 2. 发送到中央日志
$endpoint = if ($env:CLAUDE_AUDIT_ENDPOINT) { $env:CLAUDE_AUDIT_ENDPOINT } `
            else { "https://logs.internal.company.com/claude-audit" }

$headers = @{
    "Content-Type" = "application/json"
}
if ($env:CLAUDE_AUDIT_TOKEN) {
    $headers["Authorization"] = "Bearer $($env:CLAUDE_AUDIT_TOKEN)"
}

try {
    Invoke-RestMethod -Uri $endpoint -Method Post -Body $logEntry -Headers $headers -TimeoutSec 3 -ErrorAction Stop | Out-Null
} catch {
    # HTTP 失败，记录到本地（已经写过了）
    Add-Content -Path (Join-Path $logDir "upload-errors.log") -Value "[$timeCN] HTTP upload failed" -Encoding UTF8
}

# 3. 关键工具告警
$sensitiveTools = @("Write", "Edit", "MultiEdit", "Bash", "WebFetch", "WebSearch")
if ($sensitiveTools -contains $toolName -and $env:SLACK_WEBHOOK_URL) {
    $alertPayload = @{
        channel = "#claude-audit"
        text = "[AUDIT] $user used $toolName in $project ($gitBranch)"
    } | ConvertTo-Json -Compress
    
    try {
        Invoke-RestMethod -Uri $env:SLACK_WEBHOOK_URL -Method Post -Body $alertPayload `
            -Headers @{ "Content-Type" = "application/json" } -TimeoutSec 3 -ErrorAction Stop | Out-Null
    } catch {}
}

exit 0
