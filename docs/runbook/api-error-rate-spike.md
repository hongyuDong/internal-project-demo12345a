# RB-001: API 错误率飙升

> **等级**: 🟡 P1（如果登录 API → 🔴 P0）  
> **典型触发**: 5xx 错误率 > 1% 持续 5 分钟  
> **响应时间**: 15 分钟内必须响应

---

## 🚨 立即行动（5 分钟内）

### 1. 确认事故

```bash
# 看 Grafana
open https://grafana.company.com/d/user-service

# 看错误率
curl -s 'https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{job="user-service",status=~"5.."}[5m])'
```

### 2. 开事故频道

```
/incident new P1 "API error rate spike"
# 自动开 #inc-2026-XXXX，邀请 on-call + Tech Lead
```

### 3. 快速判断故障域

| 信号 | 故障域 | 跳到 |
|------|--------|------|
| 错误都是 5xx，DB 正常 | 应用层 bug | [Step A](#step-a-应用层) |
| 错误都是 5xx，DB 连接耗尽 | DB 问题 | [Step B](#step-b-db-问题) |
| 错误都是 4xx | 客户端问题 | [Step C](#step-c-客户端问题) |
| 部分 pod 5xx，其他正常 | pod 不健康 | [Step D](#step-d-pod-问题) |

---

## Step A: 应用层

### 1. 看错误日志

```bash
kubectl logs -n user-service-prod -l app=user-service --tail=500 | grep -i error | head -30
```

### 2. 看 Sentry

```bash
open https://sentry.internal.company.com/user-service/?query=is%3Aunresolved
```

### 3. 看最近的部署

```bash
kubectl rollout history deployment/user-service -n user-service-prod
```

**如果最近 30 分钟有部署** → **回滚**（最快恢复方式）

```bash
kubectl rollout undo deployment/user-service -n user-service-prod
```

---

## Step B: DB 问题

### 1. 看 DB 连接

```bash
# K8s 端
kubectl exec -it postgres-primary-0 -n user-service-prod -- psql -U admin -d users -c "
SELECT count(*), state FROM pg_stat_activity GROUP BY state;
"
```

### 2. 看慢查询

```bash
kubectl exec -it postgres-primary-0 -n user-service-prod -- psql -U admin -d users -c "
SELECT pid, query, state, query_start, wait_event 
FROM pg_stat_activity 
WHERE state = 'active' AND query_start < now() - interval '5 seconds'
ORDER BY query_start;
"
```

### 3. 看锁

```bash
kubectl exec -it postgres-primary-0 -n user-service-prod -- psql -U admin -d users -c "
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
WHERE NOT blocked_locks.granted;
"
```

### 4. 缓解（按需）

| 问题 | 缓解 |
|------|------|
| 连接耗尽 | 重启 pgbouncer / 扩容 |
| 长事务 | `SELECT pg_terminate_backend(pid)` |
| 锁等待 | 找到持锁会话，沟通后 kill |
| 慢查询 | 临时禁用相关 feature flag |

---

## Step C: 客户端问题

### 1. 看 4xx 错误分布

```bash
curl -s 'https://prometheus.company.com/api/v1/query?query=sum by (status) (rate(http_requests_total{job="user-service",status=~"4.."}[5m]))'
```

### 2. 常见 4xx 集群原因

| 错误 | 原因 | 行动 |
|------|------|------|
| 401 突增 | JWT 验证问题 / SSO 故障 | 联系 SSO 团队 |
| 403 突增 | 权限规则变更 / 配置错误 | 回滚权限配置 |
| 429 突增 | 限流配置过严 | 调高 limit（**慎用**）|
| 404 突增 | 客户端用了错的 endpoint | 通知客户端团队 |

---

## Step D: Pod 问题

### 1. 看 pod 状态

```bash
kubectl get pods -n user-service-prod -l app=user-service
```

### 2. 看 pod 详情

```bash
kubectl describe pod <pod-name> -n user-service-prod
```

### 3. 常见 pod 问题

| 状态 | 原因 | 解决 |
|------|------|------|
| CrashLoopBackOff | 启动失败 / 立即退出 | 看 logs |
| OOMKilled | 内存超限 | 增加 limit 或查泄漏 |
| ImagePullBackOff | 镜像拉不下来 | 检查 registry |
| Pending | 调度不到节点 | 扩容节点 |

### 4. 强制重启问题 pod

```bash
kubectl delete pod <problem-pod> -n user-service-prod
# Deployment 会自动重建
```

---

## 📊 缓解后验证

```bash
# 1. 错误率回落到 < 0.1%
curl -s 'https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{job="user-service",status=~"5.."}[5m])'

# 2. P99 恢复
curl -s 'https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket{job="user-service"}[5m]))'

# 3. 业务指标
- 入职成功率 > 99%
- 登录成功率 > 99%
```

---

## 📝 后续行动

1. **30 分钟稳定后**：降级处理（关闭事故频道）
2. **2 小时内**：写事故简报到 #inc-XXXX
3. **48 小时内**：完整 postmortem（用 `docs/project/postmortems/template.md`）

---

## ⚠️ 常见错误

| ❌ 不要 | ✅ 应该 |
|--------|---------|
| 盲目重启 | 先看 logs 找根因 |
| 改 DB schema 临时修 | 用 feature flag 临时 disable |
| 隐瞒不报 | 立即升级到 IC |
| 单打独斗 | 拉 Tech Lead 一起 |
