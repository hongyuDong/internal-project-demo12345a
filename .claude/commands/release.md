---
description: Run full release process for production deployment
---

# /release

Run production release process. **仅 EM/Tech Lead 可触发**，需要双重审批。

## Pre-flight（必须全部通过）

```bash
# 1. 当前在 main 分支
BRANCH=$(git rev-parse --abbrev-ref HEAD)
[ "$BRANCH" = "main" ] || { echo "❌ 必须在 main 分支"; exit 1; }

# 2. 工作区干净
git diff --quiet || { echo "❌ 工作区有修改"; exit 1; }

# 3. 与远端同步
git fetch origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "❌ 未同步"; exit 1; }

# 4. CI 全绿
gh pr checks --json state | jq -e '[.[] | select(.state != "SUCCESS")] | length == 0'

# 5. 当前版本号
CURRENT=$(cat VERSION 2>/dev/null || echo "0.0.0")
echo "📦 当前版本: $CURRENT"

# 6. 决定新版本
echo "请选择版本类型:"
echo "  1) major (破坏性变更)"
echo "  2) minor (新功能)"
echo "  3) patch (bug fix)"
read -p "选择 [1/2/3]: " VERSION_TYPE
```

## Step 1: 更新版本号 + Changelog

```bash
# 用 semver 工具
NEW_VERSION=$(semver bump $VERSION_TYPE $CURRENT)
echo "📦 新版本: $CURRENT → $NEW_VERSION"
echo "$NEW_VERSION" > VERSION

# 更新 CHANGELOG
cat >> CHANGELOG.md <<EOF
## [$NEW_VERSION] - $(date +%Y-%m-%d)

### Added
$(git log --grep="^feat" --pretty=format:"- %s" v$CURRENT..HEAD)

### Changed
$(git log --grep="^refactor\|^perf" --pretty=format:"- %s" v$CURRENT..HEAD)

### Fixed
$(git log --grep="^fix" --pretty=format:"- %s" v$CURRENT..HEAD)

### Security
$(git log --grep="^security" --pretty=format:"- %s" v$CURRENT..HEAD)
EOF

# 提交
git add VERSION CHANGELOG.md
git commit -m "chore(release): bump version to $NEW_VERSION"
```

## Step 2: 提交 PR 到 release 分支

```bash
git checkout -b release/v$NEW_VERSION
git push origin release/v$NEW_VERSION

gh pr create \
  --base main \
  --head release/v$NEW_VERSION \
  --title "[RELEASE] v$NEW_VERSION" \
  --body "Production release. See CHANGELOG.md for changes."
```

## Step 3: 审批门

```bash
# 必须 EM + SRE Lead 双 Approve
REQUIRED_APPROVERS=("@em-team" "@sre-lead")
for REVIEWER in "${REQUIRED_APPROVERS[@]}"; do
  CURRENT=$(gh pr view --json reviews --jq "[.reviews[] | select(.user.login == \"$REVIEWER\" and .state == \"APPROVED\")] | length")
  if [ "$CURRENT" = "0" ]; then
    echo "❌ 缺少 $REVIEWER 审批"
    exit 1
  fi
done

echo "✅ 所有审批通过"
```

## Step 4: Tag + 触发生产部署

```bash
# Merge release PR
gh pr merge --merge --delete-branch

# 创建 tag
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
git push origin "v$NEW_VERSION"

# Tag 推送后自动触发 release pipeline
echo "🚀 Tag 已推送，release pipeline 已启动"
echo "📊 监控: https://ci.company.com/build/$NEW_VERSION"
```

## Step 5: 部署窗口检查

```bash
# 检查是否在部署窗口内
CURRENT_HOUR=$(date +%H)
CURRENT_DOW=$(date +%u)  # 1=Mon, 7=Sun

# 部署窗口: 周二/周三/周四 10:00-16:00
if [ "$CURRENT_DOW" -gt 4 ] || [ "$CURRENT_DOW" -eq 1 ] || [ "$CURRENT_DOW" -eq 7 ]; then
  echo "⚠️ 当前不是工作日中段，是否继续？"
  read -p "输入 YES 继续: " CONFIRM
  [ "$CONFIRM" = "YES" ] || exit 1
fi

if [ "$CURRENT_HOUR" -lt 10 ] || [ "$CURRENT_HOUR" -ge 16 ]; then
  echo "⚠️ 当前不在部署时段（10:00-16:00），是否继续？"
  read -p "输入 YES 继续: " CONFIRM
  [ "$CONFIRM" = "YES" ] || exit 1
fi
```

## Step 6: 监控部署

```bash
# 1. 等部署完成
kubectl rollout status deployment/user-service -n user-service-prod --timeout=600s

# 2. 5 分钟密集监控
echo "🔍 5 分钟密集监控..."
./scripts/monitor-5min.sh user-service-prod

# 3. 30 分钟常规监控
echo "📊 30 分钟常规监控（后台）..."
nohup ./scripts/monitor-30min.sh user-service-prod > /tmp/release-monitor.log &

# 4. Sentry 告警打开
./scripts/sentry-watch.sh enable --duration=2h
```

## Step 7: 通知

```bash
./scripts/notify-slack.sh \
  "#announcements" \
  "✅ v$NEW_VERSION 已上线 ($(date -Iseconds)) - 作者: $(git config user.name) - 详见 CHANGELOG.md"

./scripts/notify-slack.sh \
  "#user-service-dev" \
  "🎉 v$NEW_VERSION 发布成功！监控 2 小时内重点关注..."
```

## Step 8: 部署后 24h 观察

- [ ] 错误率正常
- [ ] P99 延迟正常
- [ ] QPS 正常
- [ ] Sentry 无新错误
- [ ] 用户无大量投诉
- [ ] 依赖服务无异常

## 回滚（如果出问题）

```bash
# 立即回滚
kubectl rollout undo deployment/user-service -n user-service-prod

# 或者回滚到指定版本
kubectl set image deployment/user-service user-service=user-service:v$PREVIOUS -n user-service-prod

# 通知
./scripts/notify-slack.sh "#announcements" \
  "🚨 v$NEW_VERSION 已回滚到 v$PREVIOUS"

# 创建事故 + postmortem
```

## 重要约束

- **双人审批**：EM + SRE Lead
- **部署窗口**：工作日 10:00-16:00（紧急可破例）
- **双人值守**：release 期间必须有人 on-call
- **24h 观察**：部署后 24h 不能有重大变更
- **CHANGELOG 必填**：客户支持需要看变更
