#!/bin/bash
# secret-scanner.sh - 阻止 Claude 写入含密钥的文件
# 触发: PreToolUse (Write | Edit | MultiEdit)
# 退出码: 0 = 允许, 2 = 阻断

set -e

INPUT=$(cat)

# 提取工具输入（兼容 Write 和 Edit）
FILE_PATH=$(echo "$INPUT" | jq -r '
  .tool_input.file_path // 
  .tool_input.path // 
  .tool_input.notebook_path // 
  empty
')

CONTENT=$(echo "$INPUT" | jq -r '
  .tool_input.content // 
  .tool_input.new_string // 
  .tool_input.new_source // 
  empty
')

# 1. 文件路径黑名单（拒绝路径也算违规）
DENY_PATH_PATTERNS=(
  '\.env$'
  '\.env\..*'
  '/secrets/'
  'credentials'
  '\.key$'
  '\.pem$'
  '/\.ssh/'
  'id_rsa'
  'id_dsa'
  '\.aws/credentials'
  '\.kube/config'
  'service-account.*\.json'
)

for PATTERN in "${DENY_PATH_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" =~ $PATTERN ]]; then
    cat >&2 <<EOF
🚨 [secret-scanner] BLOCKED: Refused to write to sensitive path

File: $FILE_PATH
Pattern: $PATTERN

公司策略禁止 Claude 修改密钥文件。如需添加新密钥，
请通过 Vault 流程：https://vault.internal.company.com

This attempt has been logged.
EOF
    exit 2
  fi
done

# 2. 内容黑名单（扫描密钥模式）
SECRET_PATTERNS=(
  # AWS
  'AKIA[0-9A-Z]{16}'
  'ASIA[0-9A-Z]{16}'
  'aws_secret_access_key\s*=\s*["\x27][A-Za-z0-9/+=]{40}["\x27]'
  
  # GitHub
  'ghp_[a-zA-Z0-9]{36}'
  'gho_[a-zA-Z0-9]{36}'
  'ghu_[a-zA-Z0-9]{36}'
  'ghs_[a-zA-Z0-9]{36}'
  'ghr_[a-zA-Z0-9]{36}'
  'github_pat_[a-zA-Z0-9_]{82}'
  
  # GitLab
  'glpat-[a-zA-Z0-9_-]{20,}'
  
  # Anthropic / OpenAI / Cohere
  'sk-ant-[a-zA-Z0-9-]{32,}'
  'sk-[a-zA-Z0-9]{32,}'
  'sk-[a-zA-Z0-9]{20,}T3BlbkFJ[a-zA-Z0-9]{20,}'
  
  # Google
  'AIza[0-9A-Za-z_-]{35}'
  
  # Slack
  'xox[baprs]-[0-9a-zA-Z]{10,}'
  
  # 通用私钥
  '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY( BLOCK)?-----'
  '-----BEGIN CERTIFICATE REQUEST-----'
  
  # JWT (高熵字符串)
  'eyJ[a-zA-Z0-9_-]{10,}\.eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}'
  
  # 数据库连接串（带密码）
  'postgresql://[^:\s]+:[^@\s]+@'
  'mysql://[^:\s]+:[^@\s]+@'
  'mongodb://[^:\s]+:[^@\s]+@'
  'redis://[^:\s]*:[^@\s]+@'
  
  # 通用 key=value
  'password\s*=\s*["\x27][^"\x27\s]{8,}["\x27]'
  'passwd\s*=\s*["\x27][^"\x27\s]{8,}["\x27]'
  'api[_-]?key\s*=\s*["\x27][a-zA-Z0-9_-]{16,}["\x27]'
  'secret[_-]?key\s*=\s*["\x27][a-zA-Z0-9_-]{16,}["\x27]'
  'access[_-]?token\s*=\s*["\x27][a-zA-Z0-9_-]{16,}["\x27]'
  'auth[_-]?token\s*=\s*["\x27][a-zA-Z0-9_-]{16,}["\x27]'
  
  # Stripe
  'sk_live_[0-9a-zA-Z]{24,}'
  'rk_live_[0-9a-zA-Z]{24,}'
  
  # Twilio
  'AC[a-f0-9]{32}'
)

DETECTED=""
for PATTERN in "${SECRET_PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qP "$PATTERN"; then
    DETECTED="$DETECTED\n  - $PATTERN"
  fi
done

if [ -n "$DETECTED" ]; then
  cat >&2 <<EOF
🚨 [secret-scanner] BLOCKED: Potential secret detected in content

File: $FILE_PATH
Patterns matched:$DETECTED

公司策略禁止在代码中硬编码密钥。请：
1. 使用环境变量（从 Vault 注入）
2. 使用公司密钥管理服务：https://vault.internal.company.com
3. 如误报，联系 #security-team 添加白名单

This attempt has been logged and reported to security.
EOF
  exit 2
fi

# 3. 大文件预警（防止意外提交二进制）
CONTENT_SIZE=$(echo -n "$CONTENT" | wc -c)
if [ "$CONTENT_SIZE" -gt 1048576 ]; then
  cat >&2 <<EOF
⚠️  [secret-scanner] WARNING: Large file write (${CONTENT_SIZE} bytes)

File: $FILE_PATH

请确认不是误提交二进制文件（图片、压缩包等）。
如果是，请用 Git LFS：git lfs track "*.{png,jpg,gz}"
EOF
  # 仅警告，不阻断
fi

exit 0
