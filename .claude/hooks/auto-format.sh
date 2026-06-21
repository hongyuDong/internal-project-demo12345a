#!/bin/bash
# auto-format.sh - 文件保存后自动格式化
# 触发: PostToolUse (Write | Edit | MultiEdit)
# 退出码: 0 = 总是成功

set -e

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '
  .tool_input.file_path // 
  .tool_input.path // 
  empty
')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# 1. Python 文件
if [[ "$FILE_PATH" =~ \.py$ ]]; then
  # 按公司代码规范：black + isort + ruff
  if command -v uv >/dev/null 2>&1; then
    uv run black --quiet "$FILE_PATH" 2>/dev/null || true
    uv run isort --quiet "$FILE_PATH" 2>/dev/null || true
    uv run ruff check --fix --quiet "$FILE_PATH" 2>/dev/null || true
  fi
fi

# 2. JavaScript / TypeScript
if [[ "$FILE_PATH" =~ \.(js|jsx|ts|tsx)$ ]]; then
  if command -v prettier >/dev/null 2>&1; then
    prettier --write --silent "$FILE_PATH" 2>/dev/null || true
  fi
  if command -v eslint >/dev/null 2>&1; then
    eslint --fix --quiet "$FILE_PATH" 2>/dev/null || true
  fi
fi

# 3. Go
if [[ "$FILE_PATH" =~ \.go$ ]]; then
  if command -v gofmt >/dev/null 2>&1; then
    gofmt -w "$FILE_PATH" 2>/dev/null || true
  fi
  if command -v goimports >/dev/null 2>&1; then
    goimports -w "$FILE_PATH" 2>/dev/null || true
  fi
fi

# 4. Rust
if [[ "$FILE_PATH" =~ \.rs$ ]]; then
  if command -v rustfmt >/dev/null 2>&1; then
    rustfmt "$FILE_PATH" 2>/dev/null || true
  fi
  if command -v clippy-driver >/dev/null 2>&1; then
    cargo clippy --fix --allow-dirty --allow-staged "$FILE_PATH" 2>/dev/null || true
  fi
fi

# 5. Markdown
if [[ "$FILE_PATH" =~ \.md$ ]]; then
  if command -v prettier >/dev/null 2>&1; then
    prettier --write --silent "$FILE_PATH" 2>/dev/null || true
  fi
fi

# 6. YAML / JSON
if [[ "$FILE_PATH" =~ \.(yml|yaml)$ ]]; then
  if command -v yamllint >/dev/null 2>&1; then
    yamllint -d "{extends: relaxed}" "$FILE_PATH" 2>/dev/null || true
  fi
fi

if [[ "$FILE_PATH" =~ \.json$ ]]; then
  if command -v jq >/dev/null 2>&1; then
    # 验证 JSON 合法并美化
    if jq . "$FILE_PATH" >/dev/null 2>&1; then
      jq . "$FILE_PATH" > "$FILE_PATH.tmp" && mv "$FILE_PATH.tmp" "$FILE_PATH"
    fi
  fi
fi

# 7. SQL
if [[ "$FILE_PATH" =~ \.sql$ ]]; then
  if command -v sqlfluff >/dev/null 2>&1; then
    sqlfluff fix --quiet "$FILE_PATH" 2>/dev/null || true
  fi
fi

exit 0
