# notify-slack.ps1 - Slack 通知（Windows）
# 触发: Notification
# 退出码: 0 = 总是成功

$ErrorActionPreference = 'SilentlyContinue'

$input = $input | Out-String
if ([string]::IsNullOrWhiteSpace($input)) { exit 0 }

try {
    $data = $input | ConvertFrom-Json -ErrorAction SilentlyContinue
} catch {
    exit 0
}

$message = $data.message
if ([string]::IsNullOrWhiteSpace($message)) { $message = "Claude Code notification" }

$webhookUrl = $env:SLACK_WEBHOOK_URL
if ([string]::IsNullOrWhiteSpace($webhookUrl)) { exit 0 }

$channel = if ($env:CLAUDE_NOTIFY_CHANNEL) { $env:CLAUDE_NOTIFY_CHANNEL } else { "#claude-notifications" }

$payload = @{
    channel = $channel
    text = $message
    attachments = @(
        @{
            color = "good"
            fields = @(
                @{ title = "User"; value = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name; @short = $true }
                @{ title = "Host"; value = $env:COMPUTERNAME; @short = $true }
                @{ title = "Project"; value = (Get-Item $PWD).Name; @short = $false }
            )
            ts = [math]::Floor((Get-Date -UFormat %s))
        }
    )
} | ConvertTo-Json -Depth 10 -Compress

try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload `
        -Headers @{ "Content-Type" = "application/json" } -TimeoutSec 3 -ErrorAction Stop | Out-Null
} catch {}

exit 0
