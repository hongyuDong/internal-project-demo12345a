---
name: deploy-staging
description: Deploy current branch to staging environment. Requires approval and runs full pre-flight checks. Use when user says "deploy to staging" or "/deploy-staging".
---

# Deploy to Staging

部署当前分支到 staging 环境。**仅限 staging**，生产请走 release skill。

## 前置检查（必须全部通过）

```bash
# 1. 当前分支不是 main
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "main" ]; then
  echo "❌ 不能从 main 直接部署，请切到 feature 分支"
  exit 1
fi

# 2. 工作区干净
if ! git diff --quiet; then
  echo "❌ 工作区有未提交修改，请先 commit 或 stash"
  exit 1
fi

# 3. 已 push 到远端
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/$BRANCH)
if [ "$LOCAL" != "$REMOTE" ]; then
  echo "❌ 本地分支未与远端同步，请先 git push"
  exit 1
fi

# 4. CI 全绿
echo "🔍 检查 CI 状态..."
CI_STATUS=$(gh pr checks --json state 2>/dev/null | jq -r '[.[] | select(.state != "SUCCESS")] | length')
if [ "$CI_STATUS" != "0" ]; then
  echo "❌ CI 未全绿，请先修复"
  exit 1
fi

# 5. 至少 1 个 PR approve
APPROVES=$(gh pr view --json reviews --jq '[.reviews[] | select(.state == "APPROVED")] | length')
if [ "$APPROVES" -lt "1" ]; then
  echo "❌ 至少需要 1 个 PR approve"
  exit 1
fi

echo "✅ 所有前置检查通过"
```

## 部署步骤

```bash
# Step 1: 合并到 staging 分支（或用 PR 触发）
git checkout staging
git pull origin staging
git merge --no-ff origin/$BRANCH -m "Merge $BRANCH to staging"

# Step 2: 触发 CI/CD（push 后自动触发）
git push origin staging

# Step 3: 等待部署完成
echo "⏳ 等待 staging 部署..."
kubectl rollout status deployment/user-service -n user-service-staging --timeout=300s

# Step 4: 冒烟测试
echo "🧪 跑冒烟测试..."
./scripts/smoke-test.sh https://user-service.staging.internal.company.com

# Step 5: 监控 5 分钟
echo "📊 监控 5 分钟（错误率、延迟、QPS）..."
./scripts/monitor-5min.sh user-service-staging

# Step 6: 通知团队
echo "✅ 部署完成"
./scripts/notify-slack.sh "#user-service-dev" \
  "✅ Staging 部署成功 - 分支: $BRANCH - 作者: $(git config user.name)"
```

## 部署后验证 checklist

- [ ] 健康检查返回 200
- [ ] 关键端点响应正常
  - `GET /v1/users/me` 返回当前用户
  - `GET /healthz` 返回 `{"status": "ok"}`
  - `GET /readyz` 返回 200 且包含 DB / Redis / Kafka 状态
- [ ] Grafana 仪表盘无异常
  - 错误率 < 0.1%
  - P99 延迟 < 500ms
  - QPS 在预期范围
- [ ] Sentry 无新错误
- [ ] 日志正常输出

## 回滚

```bash
# 如果发现问题，立即回滚
git checkout staging
git revert HEAD
git push origin staging

kubectl rollout undo deployment/user-service -n user-service-staging

# 通知
./scripts/notify-slack.sh "#user-service-dev" \
  "🚨 Staging 部署已回滚 - 作者: $(git config user.name)"
```

## 重要约束

- **staging 仅供内部测试**，不保证 SLA
- **数据会定期重置**（每周一 03:00）
- **PII 数据用 fake**，不要用真实员工数据测试
- **大变更**（schema migration、第三方集成）需提前 24h 通知团队
