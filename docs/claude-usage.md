# Claude Code 团队使用规范

> 本文档描述 `internal-user-service` 项目中 Claude Code 的使用方法、约束和最佳实践。所有团队成员必读。

---

## 1. 安装与配置

### 1.1 安装

```bash
# 安装 Claude Code
brew install claude-code  # macOS
# 或
curl -fsSL https://claude.com/install.sh | sh

# 验证
claude --version
```

### 1.2 项目初始化（每个开发者一次）

```bash
# 克隆项目
git clone git@github.com:company/internal-user-service.git
cd internal-user-service

# 安装 hooks（关键！）
chmod +x .claude/hooks/*.sh

# 安装 Python 依赖
uv sync

# 配置本地环境
cp .mcp.json.example .mcp.json
# 编辑 .mcp.json（不要提交）

# 启动 Claude
claude
```

### 1.3 必需的环境变量

```bash
# 加到 ~/.zshrc 或 ~/.bashrc
export ANTHROPIC_API_KEY="sk-ant-..."           # 必须
export CORP_GITHUB_TOKEN="ghp_..."              # MCP
export JIRA_EMAIL="you@company.com"              # MCP
export JIRA_API_TOKEN="..."                     # MCP
export VAULT_TOKEN="s. ..."                     # MCP
export DB_READONLY_PASSWORD="..."               # MCP
export SLACK_BOT_TOKEN="xoxb-..."               # MCP
export SLACK_TEAM_ID="T..."                     # MCP
export CLAUDE_AUDIT_ENDPOINT="https://logs..."  # Audit hook
export CLAUDE_AUDIT_TOKEN="..."                 # Audit hook
export SLACK_WEBHOOK_URL="https://hooks..."     # Slack hook
```

---

## 2. 日常使用

### 2.1 推荐工作流

```bash
# 1. 创建 feature 分支
git checkout -b feat/PROJ-1234-add-bulk-import

# 2. 启动 Claude
claude

# 3. 用自然语言描述任务
> Add a new endpoint POST /v1/users/bulk-import that accepts a CSV file...
# Claude 自动调用 create-new-endpoint skill

# 4. Claude 会：
#    - 读现有代码
#    - 生成 schema / model / service / router / tests
#    - 跑测试
#    - 提示你 review

# 5. 提交 PR
git add .
git commit -m "feat(users): add bulk import endpoint [PROJ-1234]"
gh pr create
```

### 2.2 常用斜杠命令

| 命令 | 用途 |
|------|------|
| `/pr-review` | 自动 PR review（4 个 sub-agent 并行审查） |
| `/release` | 生产发版流程（仅 EM/Tech Lead） |
| `/db-migrate` | 数据库迁移（自动生成 + 验证） |
| `/deploy-staging` | 部署到 staging（已合并到 skills） |

### 2.3 常用 skills

| 触发词 | skill |
|--------|-------|
| "deploy to staging" | `deploy-staging` |
| "create endpoint for X" | `create-new-endpoint` |
| "incident" / "P0" / "production down" | `run-incident` |

### 2.4 常用 sub-agents

Claude 会在合适时机自动调用，也可在 prompt 中显式：

```
Use the security-reviewer subagent to audit the auth code.
Use the test-engineer subagent to write tests for the new feature.
Use the db-migrator subagent to review this migration.
```

---

## 3. 约束与红线 🚨

### 3.1 永远不允许（hooks 自动拦截）

```bash
# 🚫 破坏性命令
rm -rf /
sudo rm -rf /var/lib/data
chmod 777 /etc/passwd

# 🚫 密钥泄漏
# secret-scanner 会阻断任何含 AKIA/ghp_/-----BEGIN PRIVATE KEY----- 的写入
# 也不能写入 .env / credentials / *.key / *.pem

# 🚫 生产数据库破坏
psql -c "DROP DATABASE users_prod"
psql -c "TRUNCATE users"
redis-cli FLUSHALL

# 🚫 系统破坏
shutdown -h now
reboot
kill -9 1
iptables -F
```

### 3.2 必须审批（hooks 会问）

```bash
# 这些操作 Claude 会停下问你
git push origin main         # 默认拒绝，仅 EM 可放行
git commit                    # 要求 commit message
make deploy-prod              # 生产部署
kubectl apply                  # 集群变更
alembic upgrade head           # DB migration
```

### 3.3 数据安全

- **PII 数据**（员工邮箱、电话、ID）：不在 Claude 对话中粘贴
- **生产数据**：用 staging 的 fake 数据测试
- **日志**：PII 字段不能进 log（已写进 CLAUDE.md）
- **Token**：Claude 不能读取 ~/.ssh/、.aws/credentials、id_rsa

---

## 4. 最佳实践

### 4.1 任务描述要具体

```markdown
# ❌ 模糊
"优化用户 API"
"修个 bug"

# ✅ 具体
"重构 GET /v1/users：当前 P99 是 800ms，需要降到 200ms 以内。
 怀疑是 N+1 查询。请：
 1. 先用 py-spy profile
 2. 加 eager loading
 3. 加缓存
 4. 跑压测验证"

# ✅ 关联工单
"实现 PROJ-1234 的 bulk import 功能：
 - 接受 CSV 文件（最多 10000 行）
 - 异步处理，Kafka 任务队列
 - 返回 task_id 用于轮询
 - 失败行写入 dead letter queue
 - 完整测试覆盖率"
```

### 4.2 让 Claude 读上下文先

```bash
# 在 prompt 开头告诉 Claude 读哪些文件
"先读 src/api/v1/users.py、src/services/user_service.py 和 CLAUDE.md，
然后帮我..."
```

### 4.3 利用 sub-agent 并行

复杂任务可以让多个 sub-agent 并行：

```
Please run these subagents in parallel and combine results:
1. security-reviewer — review the auth code in src/services/auth_service.py
2. test-engineer — check test coverage for src/api/v1/auth.py
3. db-migrator — review migrations/versions/2026_06_21_add_oauth_tokens.py

Then summarize findings in a table.
```

### 4.4 善用 plan mode

复杂任务用 plan mode（Shift+Tab）：

```bash
claude
> [Shift+Tab]  # 进入 plan mode
> 我想重构用户权限系统...  # Claude 只读探索，给出计划
> [Shift+Tab]  # 退出 plan mode 开始执行
```

### 4.5 在 worktree 隔离实验

```bash
# 危险改动用 worktree 隔离
claude --worktree feat-experiment-rbac
# Claude 在独立 worktree 工作，不污染当前分支
```

---

## 5. 成本与配额

### 5.1 个人配额

- **Sonnet**：每月 $200
- **Opus**：每月 $50（仅 review 用）

### 5.2 优化建议

- **简单任务**用 Sonnet，省钱
- **代码审查**用 Opus，质量更高
- **避免无限循环**：Claude 卡住时用 Ctrl+C 中断
- **清理长对话**：定期 `/clear`，避免 context 膨胀

### 5.3 团队预算

| 团队 | 月预算 | 超额策略 |
|------|--------|----------|
| Backend | $2000 | 告警 EM，超额需审批 |
| Frontend | $1000 | 告警 EM |
| DevOps | $500 | 告警 SRE Lead |
| Mobile | $1000 | 告警 EM |

---

## 6. 故障排查

### 6.1 Hook 不工作

```bash
# 1. 检查可执行权限
ls -la .claude/hooks/
chmod +x .claude/hooks/*.sh

# 2. 手动测试
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.py","content":"AKIAIOSFODNN7EXAMPLE\n"}}' | .claude/hooks/secret-scanner.sh
echo "exit code: $?"  # 应该输出 2

# 3. 看 hook 日志
cat ~/.claude/logs/audit-*.jsonl | tail -5
```

### 6.2 Claude 拒绝执行

- **permission denied** → 你的命令被 deny 了，看 deny list
- **blocked by hook** → hook 拦截，看 stderr 消息
- **认证失败** → 检查 ANTHROPIC_API_KEY

### 6.3 MCP 不工作

```bash
# 1. 验证 .mcp.json 格式
jq . .mcp.json

# 2. 测试单个 MCP server
npx -y @modelcontextprotocol/server-github

# 3. 重启 Claude 让 MCP 重新加载
```

### 6.4 audit log 没送出去

```bash
# 1. 检查本地日志
ls -la ~/.claude/logs/

# 2. 检查网络
curl -v $CLAUDE_AUDIT_ENDPOINT

# 3. 手动上传
cat ~/.claude/logs/audit-2026-06-21.jsonl | curl -X POST -d @- $CLAUDE_AUDIT_ENDPOINT
```

---

## 7. 常见问题 FAQ

### Q1: Claude 改了我的代码但我不同意，怎么办？

A: 用 git 恢复：`git checkout -- <file>`。Claude 改动前你可以 review diff，Claude 默认会问你确认。

### Q2: Claude 不能访问我的数据库，怎么调试？

A: 用 MCP postgres-readonly server，配置只读连接串。**永远不要给 Claude 生产 DB 写权限**。

### Q3: Claude 写的代码我看不懂怎么办？

A: 在 prompt 中加："请逐行注释你写的代码，并解释为什么这样写。"

### Q4: Claude 会把代码泄露给外部吗？

A: 不会直接泄露（Anthropic API 不用于训练），但要注意：
- 不要在 Claude 中粘贴生产密钥
- audit hook 记录所有操作
- 定期审查 ~/.claude/logs/audit-*.jsonl

### Q5: 团队成员不愿意用 Claude 怎么办？

A: 不强制，但建议至少用 `/pr-review` 命令（提升 review 质量）。其他场景按个人偏好。

### Q6: Claude 误操作了怎么办？

A:
1. 立即 `git stash` 或 `git checkout`
2. 检查 audit log 看发生了什么
3. 如果 push 了，回滚 + postmortem
4. 联系 EM

---

## 8. 进阶用法

### 8.1 自定义 skill

团队成员可以创建自己的 skill：

```bash
mkdir -p .claude/skills/my-skill/
cat > .claude/skills/my-skill/SKILL.md <<EOF
---
name: my-skill
description: What it does
---

# Steps
1. ...
EOF
```

提交 PR 到 main → 自动生效给所有人。

### 8.2 自定义 sub-agent

```bash
cat > .claude/agents/my-agent.md <<EOF
---
name: my-agent
description: ...
tools: Read, Grep, Glob
---

You are ...
EOF
```

### 8.3 自定义命令

```bash
cat > .claude/commands/my-command.md <<EOF
---
description: What this command does
---

# Workflow
1. ...
EOF
```

### 8.4 本地覆盖

`settings.local.json`（git ignored）用于个人配置：

```json
{
  "permissions": {
    "allow": ["Bash(docker exec*)"]
  },
  "model": "opus"
}
```

---

## 9. 合规与审计

### 9.1 数据流向

```
Claude (本地) 
  ↓ API
Anthropic API (TLS 加密)
  ↓ 
审计端点 (公司内网)
  ↓
ELK / Datadog (7 年留存)
```

### 9.2 合规声明

- ✅ Claude Code 通过 SOC2 Type II 审计
- ✅ 所有 API 通信 TLS 1.3
- ✅ 数据不用于训练（API tier）
- ✅ 所有工具调用有审计日志
- ✅ 符合 GDPR / CCPA
- ⚠️ 但请不要输入生产密钥 / PII

### 9.3 审计查询

```bash
# 查某人最近的操作
jq -r 'select(.user == "zhangsan")' ~/.claude/logs/audit-2026-06-*.jsonl | tail -20

# 查敏感工具使用
jq -r 'select(.tool == "Write" or .tool == "Edit")' ~/.claude/logs/audit-2026-06-*.jsonl

# 查生产部署相关
jq -r 'select(.input.command | contains("deploy-prod"))' ~/.claude/logs/audit-*.jsonl
```

---

## 10. 联系方式

- **工具问题**：`#claude-tooling` Slack
- **安全问题**：`#security-team` Slack
- **成本问题**：EM
- **功能请求**：Tech Lead
- **紧急**：on-call SRE

---

**最后更新**：2026-06-21
**维护者**：DevEx Team
**版本**：v1.0
