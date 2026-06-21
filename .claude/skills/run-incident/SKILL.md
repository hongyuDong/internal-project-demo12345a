---
name: run-incident
description: Run incident response for production issues. Use when user says "we have an incident" or "P0" or "production down".
---

# Run Incident Response

按公司事故响应 Runbook 处理生产事故。**冷静、按步骤、不要瞎搞**。

## 第 0 步：定级（2 分钟内）

| 级别 | 标准 | 例子 | 响应时间 |
|------|------|------|----------|
| **P0** | 全站不可用 / 数据丢失 / 安全漏洞 | 登录挂、数据库挂、数据被删、被攻击 | 立即 |
| **P1** | 核心功能受损 / 性能严重下降 | 创建用户失败、P99 > 5s | 15 分钟 |
| **P2** | 非核心功能受损 | 头像上传失败、邮件通知延迟 | 4 小时 |
| **P3** | 小 bug / 优化 | 文案错误、UI 错位 | 下个工作日 |

**当你不确定，定高一级。**

## 第 1 步：开事故频道（1 分钟内）

```bash
# 1. 创建 Slack 频道
./scripts/incident-create.sh P0 "User login failing"
# 自动创建: #inc-2026-06-21-user-login
# 自动 invite: on-call 工程师 + Tech Lead + EM + SRE

# 2. 启动 Zoom / 腾讯会议
./scripts/incident-zoom.sh

# 3. 启动 Incident Commander 角色
# IC 是事故的"指挥官"，不一定是技术最强的人
```

## 第 2 步：确认影响范围（5 分钟内）

```bash
# 1. 看监控
open https://grafana.company.com/d/user-service

# 关键指标
- 错误率:    正常 0.05%, 现在 25% 🚨
- P99 延迟:  正常 200ms, 现在 8000ms 🚨
- QPS:       正常 5000/s, 现在 200/s 🚨
- DB 连接:   正常 50, 现在 200 🚨 (打满)

# 2. 看错误日志
kubectl logs -n user-service -l app=user-service --tail=200 | grep -i error

# 3. 看 Sentry
open https://sentry.internal.company.com/user-service

# 4. 看告警
open https://alertmanager.company.com

# 5. 评估影响用户数
./scripts/affected-users.sh "user login failing"
# 输出: ~12,000 用户在过去 10 分钟受影响
```

## 第 3 步：定 Incident Commander + 角色

| 角色 | 谁 | 职责 |
|------|------|------|
| **IC** | 第一个响应的资深工程师 | 指挥、协调、决策，**不写代码** |
| **Comms Lead** | EM / PM | 对内对外沟通 |
| **Tech Lead** | 最熟悉服务的人 | 排障、写代码 |
| **Scribe** | 任何人 | 记录每一步（用于事后复盘） |

## 第 4 步：缓解（Mitigation）— 先止血

> **目标**：恢复服务 > 找根因

### 4.1 立即回滚（如果最近 30 分钟有部署）

```bash
# 看最近部署
kubectl rollout history deployment/user-service -n user-service

# 回滚到上一版本
kubectl rollout undo deployment/user-service -n user-service

# 监控 5 分钟看错误率
watch -n 5 'curl -s https://user-service.company.com/healthz'
```

### 4.2 扩容（如果是被流量打挂）

```bash
# 紧急扩容（5 → 20 个 pod）
kubectl scale deployment/user-service -n user-service --replicas=20

# 同步扩容 DB 连接池（修改 ConfigMap 后 apply）
kubectl apply -f k8s/db-pool-overrides.yaml
```

### 4.3 限流（如果怕数据库挂）

```bash
# 启用紧急限流（10% 流量）
./scripts/emergency-rate-limit.sh --percent=10

# 关键用户白名单（CEO/CTO 等）
./scripts/rate-limit-whitelist.sh --emails="ceo@company.com,cto@company.com"
```

### 4.4 切只读模式（如果数据库有风险）

```bash
# 切到只读模式，禁止写操作
./scripts/maintenance-mode.sh --readonly --message="数据库维护中"
```

### 4.5 启用维护页面（如果用户能感知）

```bash
# 启用静态维护页
./scripts/maintenance-mode.sh --message="我们正在紧急修复，预计 30 分钟内恢复"
```

## 第 5 步：找根因（Root Cause）

> **只有服务恢复后**才进这一步

### 5.1 常见根因清单

```markdown
## 近期变更
- [ ] 最近 30 分钟部署？
- [ ] 最近 DB schema 变更？
- [ ] 最近配置变更？
- [ ] 最近第三方依赖升级？

## 流量
- [ ] 异常流量（攻击、爬虫、刷接口）？
- [ ] 大客户突发？
- [ ] 营销活动？

## 依赖
- [ ] DB / Redis / Kafka 异常？
- [ ] 下游服务故障？
- [ ] 第三方 API 故障？

## 资源
- [ ] CPU / 内存 / 磁盘打满？
- [ ] 网络抖动？
- [ ] DNS 故障？

## 代码
- [ ] 最近 hotfix？
- [ ] 新功能引入的 bug？
```

### 5.2 排障工具

```bash
# 1. 看 pod 状态
kubectl get pods -n user-service -l app=user-service
kubectl describe pod <pod-name> -n user-service

# 2. 进入 pod 调试（生产慎用！）
kubectl exec -it <pod-name> -n user-service -- /bin/bash

# 3. 实时日志
kubectl logs -f -n user-service -l app=user-service

# 4. 数据库慢查询
psql -h db.prod.company.com -U admin -d users -c "
SELECT pid, query, state, wait_event_type, wait_event, query_start 
FROM pg_stat_activity 
WHERE state = 'active' AND query_start < now() - interval '5 seconds'
ORDER BY query_start;
"

# 5. Profiling（在线）
py-spy dump --pid <pid>
py-spy record -o /tmp/profile.svg --pid <pid> --duration 30
```

## 第 6 步：修复（Fix）

```bash
# Hotfix 流程
git checkout main
git pull
git checkout -b hotfix/fix-incident-2026-06-21-user-login

# 改代码（最小修改 + 单元测试）
# ...

# 紧急流程：直接 PR + 2 个 approver 可绕过常规流程
gh pr create --label "hotfix" --reviewer tech-lead,sre-lead

# merge 后自动部署（hotfix pipeline 跳过 staging）
# 部署后监控 30 分钟
```

## 第 7 步：解除事故

```bash
# 1. 确认所有指标恢复正常
- 错误率 < 0.1%
- P99 < 500ms
- QPS 恢复正常
- Sentry 无新错误

# 2. 通知全公司
./scripts/announce.sh "服务已恢复正常，事故根因将在 24h 内 post-mortem"

# 3. 关闭事故频道
./scripts/incident-close.sh

# 4. 安排 post-mortem 会议
# - 必须 24-48h 内开
# - 所有相关人员参加
# - 输出 Postmortem 文档
```

## 第 8 步：Postmortem（24-48 小时内）

文档模板 `docs/postmortems/YYYY-MM-DD-{slug}.md`：

```markdown
# Postmortem: User Login Failure

**日期**: 2026-06-21
**等级**: P0
**持续时间**: 14:23 - 15:47 (84 分钟)
**影响**: ~30,000 用户无法登录
**IC**: 张三
**Tech Lead**: 李四

## 时间线
- 14:23 - 告警: 错误率从 0.05% 涨到 25%
- 14:25 - IC 确认 P0，开 #inc-... 频道
- 14:32 - 发现是 PR #1234 引入的回归
- 14:38 - 回滚到上一版本
- 14:45 - 错误率回落到 0.1%
- 15:47 - 确认完全恢复

## 根因
PR #1234 在 `auth_service.py` 改了 session validation，遗漏了 null 检查。
当 Redis session 过期返回 null 时，新代码抛 500。

## 为什么没在 staging 抓到
- staging 数据量小，Redis session 几乎不会过期
- 集成测试没覆盖 Redis null 场景

## 为什么告警到 P0 才被注意
- P99 告警阈值设在 1s，正常用户感知前已经触发
- 但值班的同事手机静音

## 修复
- [x] 回滚 PR #1234
- [x] 加 null check（PR #1235）
- [x] 加 Redis null 集成测试（PR #1236）

## 行动项
- [ ] (Owner: 李四, Due: 2026-06-28) 集成测试覆盖所有 Redis 异常路径
- [ ] (Owner: 王五, Due: 2026-06-25) 把告警升级到电话
- [ ] (Owner: 张三, Due: 2026-07-01) staging 用更接近生产的数据集

## 学到的教训
1. **集成测试必须覆盖依赖异常路径**（Redis/Down/Kafka Lag）
2. **staging 必须用接近生产的数据量**
3. **告警不应只在 Slack，手机电话必接**
```

## 重要原则

| ✅ 做 | ❌ 不做 |
|-------|---------|
| 立即开事故频道 | 私下修复不通知 |
| IC 不写代码 | 多人同时改代码 |
| 先缓解再找根因 | 边改边查 |
| 所有动作记录时间线 | 凭记忆复盘 |
| 修复后立刻写热修测试 | "修好了，就这样" |
| 24h 内 postmortem | 拖到下周 |
| 不指责个人 | "是谁搞的？" |

## 速查卡

```
IC:    指挥 + 决策 + 沟通
Tech:  排障 + 写代码
Scribe: 记录 + 时间线
Comms: 对外 + 对内 + 高管
```
