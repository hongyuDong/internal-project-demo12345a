#!/bin/bash
# bash-policy.sh - Bash 命令策略检查
# 触发: PreToolUse (Bash)
# 退出码: 0 = 允许, 2 = 阻断

set -e

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# 1. 黑名单命令（即便 allow 也要二次拦截）
BLACKLIST_PATTERNS=(
  # 破坏性删除
  '^rm\s+(-[a-zA-Z]*[rf][a-zA-Z]*\s+)*[/~].*'
  '^rm\s+-rf?\s+/'
  '^find\s+.*-delete.*-path\s+[/~]'
  
  # 权限提升
  '^sudo\s'
  '^su\s'
  '^doas\s'
  
  # 远程执行
  '^curl\s.*\|\s*(bash|sh|zsh)'
  '^wget\s.*\|\s*(bash|sh|zsh)'
  '^curl\s+-o-?\s.*https?://.*\s*\|\s*(bash|sh)'
  '^nc\s.*-e\s'
  '^bash\s*<.*\(curl|wget\)'
  
  # Shell 注入
  '^eval\s'
  '^exec\s'
  ':(){ :\|:& };:'  # Fork bomb
  
  # 系统破坏
  '^mkfs\.'
  '^dd\s+if=.*of=/dev/'
  '>\s*/dev/sd[a-z]'
  '^chmod\s+-R\s+777'
  '^chown\s+-R\s'
  
  # 服务影响
  '^shutdown\s'
  '^reboot\s'
  '^halt\s'
  '^init\s+[016]'
  '^systemctl\s+(stop|disable|mask)\s+(ssh|sshd|network|firewalld)'
  
  # 进程杀手
  '^kill\s+-9\s+1\b'
  '^pkill\s+-9\s+-f\s+(init|ssh|systemd)'
  
  # Cron / Systemd 修改
  '^crontab\s+-r'
  '^crontab\s+.*<<'
  '>\s*/etc/(crontab|cron\.d|cron\.daily|cron\.hourly)'
  '>\s*/etc/systemd/system/'
  '>\s*/etc/init\.d/'
  
  # iptables / 网络破坏
  '^iptables\s+-F'
  '^iptables\s+-X'
  '^ufw\s+disable'
  '^firewall-cmd\s+--reload'
  
  # 数据库破坏（生产）
  '^psql\s.*-c\s+["\x27].*DROP\s+(DATABASE|TABLE)\s'
  '^psql\s.*-c\s+["\x27].*TRUNCATE\s'
  '^mysql\s.*-e\s+["\x27].*DROP\s+(DATABASE|TABLE)\s'
  '^mongo\s.*--eval\s+["\x27].*dropDatabase'
  '^redis-cli\s.*FLUSHALL'
  '^redis-cli\s.*FLUSHDB'
)

for PATTERN in "${BLACKLIST_PATTERNS[@]}"; do
  if [[ "$COMMAND" =~ $PATTERN ]]; then
    cat >&2 <<EOF
🚨 [bash-policy] BLOCKED: Dangerous command pattern detected

Command: $COMMAND
Pattern: $PATTERN

公司策略禁止此操作。如确有必要：
1. 联系 SRE 团队 #sre-team
2. 在维护窗口执行
3. 走变更审批流程

This attempt has been logged.
EOF
    exit 2
  fi
done

# 2. 强制要求的工作目录
# 禁止写 outside project root（防止 /etc、/var 修改）
WORKDIR_TOUCH=$(echo "$COMMAND" | grep -oE '/(etc|var|usr|root|home)/[a-zA-Z0-9_/.-]+' | head -1 || true)
if [ -n "$WORKDIR_TOUCH" ]; then
  # 例外：/tmp 允许
  if [[ ! "$WORKDIR_TOUCH" =~ ^/tmp/ ]]; then
    # 例外：read-only 命令允许
    if [[ ! "$COMMAND" =~ ^(ls|cat|head|tail|grep|find|wc|stat)\s ]]; then
      cat >&2 <<EOF
⚠️  [bash-policy] WARNING: Command touches system path

Command: $COMMAND
Path: $WORKDIR_TOUCH

请确认是否真的需要修改系统目录。如无必要，请在项目目录内操作。
EOF
      # 仅警告，不阻断（很多合法命令需要读 /etc/hosts 等）
    fi
  fi
fi

# 3. 长命令预警（防止 paste 错乱）
COMMAND_LEN=$(echo -n "$COMMAND" | wc -c)
if [ "$COMMAND_LEN" -gt 2000 ]; then
  cat >&2 <<EOF
⚠️  [bash-policy] WARNING: Very long command (${COMMAND_LEN} chars)

建议拆成多个小命令或写到脚本文件执行。
EOF
fi

exit 0
