#!/bin/bash
# notify-slack.sh - Slack 通知
# 触发: Notification
# 退出码: 0 = 总是成功

set -e

INPUT=$(cat)

MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code notification"')
CHANNEL="${CLAUDE_NOTIFY_CHANNEL:-#claude-notifications}"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

if [ -z "$WEBHOOK_URL" ]; then
  # 没有 webhook URL，静默跳过
  exit 0
fi

PAYLOAD=$(jq -c -n \
  --arg channel "$CHANNEL" \
  --arg text "$MESSAGE" \
  --arg user "$(whoami)" \
  --arg host "$(hostname)" \
  --arg proj "$(basename $(pwd))" \
  '{
    channel: $channel,
    text: $text,
    attachments: [{
      color: "good",
      fields: [
        { title: "User", value: $user, short: true },
        { title: "Host", value: $host, short: true },
        { title: "Project", value: $proj, short: false }
      ],
      ts: (now | floor)
    }]
  }')

curl -s -X POST \
  -H "Content-Type: application/json" \
  --max-time 3 \
  -d "$PAYLOAD" \
  "$WEBHOOK_URL" >/dev/null 2>&1 || true

exit 0
