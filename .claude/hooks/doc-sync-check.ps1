# doc-sync-check.ps1 - 检查代码与文档是否同步（Windows）
# 触发: PostToolUse (Write | Edit)
# 退出码: 0 = 允许（有警告但不阻断）

$ErrorActionPreference = 'SilentlyContinue'

$input = $input | Out-String
if ([string]::IsNullOrWhiteSpace($input)) { exit 0 }

try {
    $data = $input | ConvertFrom-Json -ErrorAction SilentlyContinue
} catch {
    exit 0
}

$toolInput = $data.tool_input
$filePath = if ($toolInput.PSObject.Properties['file_path']) { $toolInput.file_path } `
            elseif ($toolInput.PSObject.Properties['path']) { $toolInput.path } `
            else { $null }

if (-not $filePath) { exit 0 }

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }

$warnings = @()

# 1. 改了 API 但没更新 API 文档
if ($filePath -match 'src/api/' -and $filePath -notmatch 'test') {
    $docsApi = Join-Path $projectDir "docs/api"
    if (Test-Path $docsApi) {
        $today = Get-Date -Format "yyyy-MM-dd"
        $changelog = Join-Path $docsApi "changelog.md"
        if ((Test-Path $changelog) -and -not (Select-String -Path $changelog -Pattern $today -SimpleMatch -Quiet)) {
            $warnings += "[WARN] API 改了，但 docs/api/changelog.md 今天没更新"
        }
    }
}

# 2. 改了 model 但没更新 domain 文档
if ($filePath -match 'src/models/') {
    $modelName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    $entityDoc = Join-Path $projectDir "docs/domain/entities/$modelName.md"
    if (-not (Test-Path $entityDoc)) {
        $warnings += "[WARN] Model 改了，但 docs/domain/entities/$modelName.md 不存在"
    }
}

# 3. 改了 services 但 BR 文件陈旧
if ($filePath -match 'src/services/') {
    $brFile = Join-Path $projectDir "docs/requirements/business-rules.md"
    if ((Test-Path $brFile) -and ($filePath -match 'BR-')) {
        $brAge = (Get-Date) - (Get-Item $brFile).LastWriteTime
        if ($brAge.Days -gt 90) {
            $warnings += "[WARN] Service 引用 BR-*，但 business-rules.md 已 $($brAge.Days) 天未更新"
        }
    }
}

# 4. 改了依赖
if ($filePath -match 'pyproject\.toml|requirements.*\.txt|Pipfile|package\.json$') {
    $adrDir = Join-Path $projectDir "docs/architecture/adr"
    if (Test-Path $adrDir) {
        $latestAdr = Get-ChildItem -Path $adrDir -Filter "*.md" -ErrorAction SilentlyContinue |
                     Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestAdr) {
            $adrAge = (Get-Date) - $latestAdr.LastWriteTime
            if ($adrAge.Days -gt 180) {
                $warnings += "[WARN] 依赖改了，但 ADR 最近更新 $($adrAge.Days) 天前"
            }
        }
    }
}

if ($warnings.Count -gt 0) {
    [Console]::Error.WriteLine ""
    [Console]::Error.WriteLine "============================================="
    [Console]::Error.WriteLine "  [doc-sync-check] 文档同步提醒"
    [Console]::Error.WriteLine "============================================="
    foreach ($w in $warnings) {
        [Console]::Error.WriteLine "  $w"
    }
    [Console]::Error.WriteLine "============================================="
}

exit 0
