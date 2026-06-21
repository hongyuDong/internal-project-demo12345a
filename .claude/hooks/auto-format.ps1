# auto-format.ps1 - 文件保存后自动格式化（Windows）
# 触发: PostToolUse (Write | Edit | MultiEdit)
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
if ($toolName -notin @('Write', 'Edit', 'MultiEdit')) { exit 0 }

$toolInput = $data.tool_input
$filePath = if ($toolInput.PSObject.Properties['file_path']) { $toolInput.file_path } `
            elseif ($toolInput.PSObject.Properties['path']) { $toolInput.path } `
            else { $null }

if (-not $filePath -or -not (Test-Path $filePath)) { exit 0 }

# Python (用 uv)
if ($filePath -match '\.py$') {
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        uv run black --quiet $filePath 2>$null
        uv run isort --quiet $filePath 2>$null
        uv run ruff check --fix --quiet $filePath 2>$null
    }
}

# TypeScript / JavaScript
elseif ($filePath -match '\.(ts|tsx|js|jsx)$') {
    if (Get-Command prettier -ErrorAction SilentlyContinue) {
        prettier --write --silent $filePath 2>$null
    }
    if (Get-Command eslint -ErrorAction SilentlyContinue) {
        eslint --fix --quiet $filePath 2>$null
    }
}

# Go
elseif ($filePath -match '\.go$') {
    if (Get-Command gofmt -ErrorAction SilentlyContinue) {
        gofmt -w $filePath 2>$null
    }
}

# Rust
elseif ($filePath -match '\.rs$') {
    if (Get-Command rustfmt -ErrorAction SilentlyContinue) {
        rustfmt $filePath 2>$null
    }
}

# JSON (格式化)
elseif ($filePath -match '\.json$') {
    if (Get-Command jq -ErrorAction SilentlyContinue) {
        $content = Get-Content $filePath -Raw
        $formatted = $content | ConvertFrom-Json -Depth 100 | ConvertTo-Json -Depth 100
        Set-Content -Path $filePath -Value $formatted -Encoding UTF8
    }
}

# Markdown
elseif ($filePath -match '\.md$') {
    if (Get-Command prettier -ErrorAction SilentlyContinue) {
        prettier --write --silent $filePath 2>$null
    }
}

# YAML
elseif ($filePath -match '\.(yml|yaml)$') {
    if (Get-Command prettier -ErrorAction SilentlyContinue) {
        prettier --write --silent $filePath 2>$null
    }
}

exit 0
