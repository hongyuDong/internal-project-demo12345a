# RB-005: 用户无法登录

> **等级**: 🔴 P0（所有人都无法登录 = 全公司停摆）  
> **典型触发**: 登录 API 错误率 > 50% 或 SSO 集成失败  
> **响应时间**: 立即（≤ 5 分钟）

---

## 🚨 立即行动（2 分钟内）

### 1. 确认范围

```bash
# 错误率
curl -s 'https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{job="user-service",status=~"5..",path="/v1/auth"}[5m])'

# 影响用户数（估算）
curl -s 'https://prometheus.company.com/api/v1/query?query=count(rate(http_requests_total{job="user-service",path="/v1/auth/me"}[5m]) > 0)'
```

### 2. 立即开事故

```
/incident new P0 "User login failing"
# 自动开 #inc-XXXX
# 邀请: on-call + EM + SRE Lead + Tech Lead
```

### 3. 通知

```bash
# Slack #announcements
echo "🔴 调查中: 用户登录异常，预计 15 分钟内更新" > status.txt
./scripts/update-status.sh "investigating"

# PagerDuty
./scripts/page-team.sh "P0: 用户登录异常"
```

---

## 🔍 5 分钟定位

### 检查清单（按顺序）

```
[ ] 1. user-service 应用层 OK？
[ ] 2. SSO 服务 OK？
[ ] 3. DB 可达？
[ ] 4. Redis 可达？
[ ] 5. JWT 公钥有效？
[ ] 6. 最近是否有部署？
[ ] 7. 最近是否有配置变更？
```

### 1. 应用层

```bash
# 健康检查
curl -s https://user.company.com/healthz
curl -s https://user.company.com/readyz

# 应用日志
kubectl logs -n user-service-prod -l app=user-service --tail=200 | grep -i "auth\|jwt\|login" | tail -30
```

### 2. SSO

```bash
# SSO 健康
curl -s https://sso.company.com/healthz

# JWKS 可达
curl -s https://sso.company.com/.well-known/jwks.json | head -5
```

### 3. 数据库

```bash
kubectl exec -it postgres-primary-0 -n user-service-prod -- psql -U admin -d users -c "SELECT 1;"
```

### 4. Redis

```bash
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli ping
```

---

## 🛠 常见修复

### A. SSO JWKS 公钥过期

**症状**: JWT 验签失败，日志 `JWT signature invalid`

**修复**:
```bash
# 1. 强制刷新 JWKS 缓存
kubectl exec -it <pod> -n user-service-prod -- \
  curl -X POST http://localhost:8000/admin/refresh-jwks

# 2. 如果还不行，重启 pod
kubectl rollout restart deployment/user-service -n user-service-prod
```

### B. 数据库慢查询

**症状**: `/v1/auth/me` 超时

**修复**: 见 [api-error-rate-spike.md](api-error-rate-spike.md#step-b-db-问题)

### C. 用户权限缓存失效导致雪崩

**症状**: Redis 挂了，所有请求直查 DB

**修复**:
```bash
# 1. 启用 cache-bypass flag（直查 DB，不走缓存）
ld flag set user-service.cache-bypass --enabled true

# 2. 恢复 Redis
kubectl rollout restart statefulset/redis-cluster -n user-service-prod

# 3. 等缓存预热后，关闭 cache-bypass
ld flag set user-service.cache-bypass --enabled false
```

### D. 部署引入 bug

**症状**: 最近有部署，错误率突增

**修复**:
```bash
# 立即回滚
kubectl rollout undo deployment/user-service -n user-service-prod

# 看回滚状态
kubectl rollout status deployment/user-service -n user-service-prod
```

### E. 凭据泄露 / 安全事件

**症状**: 大量异常登录尝试

**修复**: 见 [security-incident.md](security-incident.md)

---

## 🚑 临时方案（如果 15 分钟内无法恢复）

### 方案 1: 启用维护模式

```bash
# 让所有用户看到维护页
ld flag set user-service.maintenance-mode --enabled true

# 设置维护页文案
ld flag set user-service.maintenance-message --value "我们正在紧急修复登录问题，预计 30 分钟内恢复"
```

### 方案 2: SSO 临时绕过（仅极端情况）

```bash
# 临时接受过期 JWT（生产慎用！）
ld flag set user-service.skip-jwt-exp-check --enabled true
```

### 方案 3: 只读模式

```bash
# 所有写操作禁用，仅允许读
ld flag set user-service.readonly-mode --enabled true
```

---

## 📊 恢复验证

```bash
# 1. 错误率 < 0.1%
curl -s 'https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{job="user-service",status=~"5..",path="/v1/auth"}[5m])'

# 2. P99 < 300ms
curl -s 'https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket{job="user-service",path="/v1/auth/me"}[5m]))'

# 3. 抽样测试（人工）
curl -s -H "Authorization: Bearer $TEST_TOKEN" \
     https://user.company.com/v1/users/me
```

---

## 📝 通知模板

### 事故开始

```
🔴 事故进行中 - 用户登录异常
- 开始时间: 14:23
- 影响: 约 30,000 用户无法登录
- 状态: 调查中
- IC: @张三
- 频道: #inc-2026-XXXX
- 下次更新: 14:35 (15 分钟内)
```

### 事故进展（每 15 分钟）

```
🟡 进展更新 - 14:35
- 已定位: Redis 集群节点 2 故障
- 进行中: 启用 cache-bypass + 重启 Redis
- 预计恢复: 14:50
```

### 事故恢复

```
🟢 已恢复 - 14:50
- 根因: Redis 集群节点 2 故障导致权限查询超时
- 修复: 启用 cache-bypass + 重启故障节点
- 影响时长: 27 分钟
- 受影响用户: 约 30,000
- 后续: 48h 内 postmortem
```

---

## ⚠️ 关键决策点

### 何时启动维护模式？

| 条件 | 决策 |
|------|------|
| 30 分钟未恢复 | ✅ 启动 |
| 用户已开始大量投诉 | ✅ 提前启动 |
| 部分功能可用 | ❌ 继续修复 |
| 有替代方案 | ❌ 用替代方案 |

### 何时升级到 P0 通知全公司？

| 条件 | 决策 |
|------|------|
| 全公司都受影响 | ✅ 立即 |
| 多个服务依赖用户服务 | ✅ 立即 |
| 持续 > 15 分钟 | ✅ 立即 |
| 仅部分用户 | ❌ 暂时不通知 |

---

## 🔗 相关 Runbook

- [API 错误率飙升](api-error-rate-spike.md)
- [Redis 宕机](redis-down.md)
- [数据库故障](db-primary-failure.md)
- [性能突降](performance-degradation.md)
- [事故 Postmortem 模板](../project/postmortems/template.md)
