# secret-scanner.ps1 - 阻止 Claude 写入含密钥的文件
# 触发: PreToolUse (Write | Edit | MultiEdit)
# 退出码: 0 = 允许, 2 = 阻断

$ErrorActionPreference = 'Stop'

# 读 Claude Code 传入的 JSON
$input = $input | Out-String
if ([string]::IsNullOrWhiteSpace($input)) { exit 0 }

try {
    $data = $input | ConvertFrom-Json -ErrorAction SilentlyContinue
} catch {
    exit 0
}

# 提取工具输入
$toolInput = $data.tool_input
if ($null -eq $toolInput) { exit 0 }

$filePath = if ($toolInput.PSObject.Properties['file_path']) { $toolInput.file_path } `
            elseif ($toolInput.PSObject.Properties['path']) { $toolInput.path } `
            elseif ($toolInput.PSObject.Properties['notebook_path']) { $toolInput.notebook_path } `
            else { $null }

$content = if ($toolInput.PSObject.Properties['content']) { $toolInput.content } `
           elseif ($toolInput.PSObject.Properties['new_string']) { $toolInput.new_string } `
           elseif ($toolInput.PSObject.Properties['new_source']) { $toolInput.new_source } `
           else { $null }

# 路径黑名单
$denyPathPatterns = @(
    '\.env$',
    '\.env\..*',
    '/secrets/',
    'credentials',
    '\.key$',
    '\.pem$',
    '/\.ssh/',
    'id_rsa',
    'id_dsa',
    '\.aws/credentials',
    '\.kube/config',
    'service-account.*\.json'
)

if ($filePath) {
    foreach ($pattern in $denyPathPatterns) {
        if ($filePath -match $pattern) {
            [Console]::Error.WriteLine(@"
🚨 [secret-scanner] BLOCKED: Refused to write to sensitive path

File: $filePath
Pattern: $pattern

公司策略禁止 Claude 修改密钥文件。
如需添加密钥，请通过 Vault: https://vault.internal.company.com

This attempt has been logged.
"@)
            exit 2
        }
    }
}

if (-not $content) { exit 0 }

# 密钥 pattern
$secretPatterns = @(
    @{ Name = 'AWS Access Key'; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Name = 'AWS Session Token'; Pattern = 'ASIA[0-9A-Z]{16}' },
    @{ Name = 'GitHub PAT'; Pattern = 'ghp_[a-zA-Z0-9]{36}' },
    @{ Name = 'GitHub OAuth'; Pattern = 'gh[osur]_[a-zA-Z0-9]{36}' },
    @{ Name = 'GitLab PAT'; Pattern = 'glpat-[a-zA-Z0-9_-]{20,}' },
    @{ Name = 'Anthropic Key'; Pattern = 'sk-ant-[a-zA-Z0-9-]{32,}' },
    @{ Name = 'OpenAI Key'; Pattern = 'sk-[a-zA-Z0-9]{20,}' },
    @{ Name = 'Google API Key'; Pattern = 'AIza[0-9A-Za-z_-]{35}' },
    @{ Name = 'Slack Token'; Pattern = 'xox[baprs]-[0-9a-zA-Z]{10,}' },
    @{ Name = 'Private Key'; Pattern = '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY( BLOCK)?-----' },
    @{ Name = 'JWT'; Pattern = 'eyJ[a-zA-Z0-9_-]{10,}\.eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}' },
    @{ Name = 'Stripe Live Key'; Pattern = 'sk_live_[0-9a-zA-Z]{24,}' },
    @{ Name = 'Twilio'; Pattern = 'AC[a-f0-9]{32}' }
)

$detected = @()
foreach ($pattern in $secretPatterns) {
    if ($content -match $pattern.Pattern) {
        $detected += "  - $($pattern.Name)"
    }
}

if ($detected.Count -gt 0) {
    [Console]::Error.WriteLine(@"
🚨 [secret-scanner] BLOCKED: Potential secret detected

File: $filePath
Patterns matched:
$($detected -join "`n")

公司策略禁止在代码中硬编码密钥。请：
1. 使用环境变量（从 Vault 注入）
2. 使用公司密钥管理服务
3. 如误报，联系 #security-team 添加白名单

This attempt has been logged and reported to security.
"@)
    exit 2
}

exit 0
