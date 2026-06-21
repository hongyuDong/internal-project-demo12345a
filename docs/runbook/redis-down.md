# RB-003: Redis 宕机

> **等级**: 🟡 P1（如果完全宕机 → 🔴 P0）  
> **典型触发**: Redis 错误率 > 5% 或延迟 > 100ms  
> **响应时间**: 15 分钟内

---

## 🚨 立即确认

```bash
# 1. Redis 健康
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli ping
# 期望: PONG

# 2. 集群状态
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli cluster info
# 看 cluster_state:ok

# 3. 节点状态
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli cluster nodes
```

---

## ⚡ 立即缓解

### 启用 cache-bypass 模式（自动降级到直查 DB）

```bash
# 通过 LaunchDarkly
ld flag set user-service.cache-bypass --enabled true
```

**效果**：
- ✅ API 不再因 Redis 故障而失败
- ⚠️ DB 压力会上升 10x（缓存命中率 90% → 0）
- ⚠️ API 延迟从 200ms 上升到 500ms+

### 触发 HPA 自动扩容应用 pod

```bash
# 手动扩容（如果 HPA 反应慢）
kubectl scale deployment/user-service -n user-service-prod --replicas=20
```

### 监控 DB 压力

```bash
# DB 连接数
curl -s 'https://prometheus.company.com/api/v1/query?query=pg_stat_activity_count'

# DB CPU
curl -s 'https://prometheus.company.com/api/v1/query?query=pg_cpu_usage'
```

---

## 🔍 诊断

### A. 单个节点故障

**症状**: 某个 pod 报错，其他正常

**原因**: 单个 Redis 实例崩溃 / OOM

**修复**:
```bash
# 1. 重启故障 pod
kubectl delete pod redis-cluster-2 -n user-service-prod

# 2. StatefulSet 自动重建

# 3. 等集群恢复（< 30s）
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli cluster info
```

### B. 集群分裂 / 网络分区

**症状**: 部分节点不可达，错误率上升

**修复**:
```bash
# 1. 看网络
kubectl get pods -n user-service-prod -l app=redis -o wide

# 2. 看 NetworkPolicy
kubectl describe networkpolicy -n user-service-prod

# 3. 重启 Redis 客户端（user-service pod）
kubectl rollout restart deployment/user-service -n user-service-prod
```

### C. 内存耗尽 (OOM)

**症状**: Redis 报 `OOM command not allowed`

**检查**:
```bash
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli info memory
# 看 used_memory_human 和 maxmemory_human
```

**修复**:
```bash
# 1. 看哪些 key 占内存
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli --bigkeys

# 2. 清理过期 / 不需要的大 key
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli --scan --pattern 'temp:*' | xargs ... DEL

# 3. 长期：增加内存 / 调整 maxmemory-policy
```

### D. 慢查询 / 大 key

**症状**: Redis 延迟突增

**检查**:
```bash
kubectl exec -it redis-cluster-0 -n user-service-prod -- redis-cli slowlog get 20
```

**修复**: 优化调用方代码，避免大 key

---

## 🔄 恢复后

### 1. 关闭 cache-bypass

```bash
# 确认 Redis 稳定 5+ 分钟后
ld flag set user-service.cache-bypass --enabled false
```

### 2. 缓存预热

```bash
# 触发主动预热（如果有此功能）
kubectl exec -it <pod> -n user-service-prod -- \
  curl -X POST http://localhost:8000/admin/warm-cache

# 否则等自然预热（5-10 分钟）
```

### 3. 恢复正常副本数

```bash
kubectl scale deployment/user-service -n user-service-prod --replicas=3
# HPA 会自动调整
```

---

## 🛡️ 长期改进

### 监控指标

| 指标 | 阈值 | 告警 |
|------|------|------|
| Redis 连接数 | > 80% maxclients | 🟡 |
| Redis 内存使用 | > 80% maxmemory | 🟡 |
| Redis 延迟 P99 | > 10ms | 🟡 |
| Redis 错误率 | > 1% | 🟡 |
| Redis 集群节点 down | 任何节点 | 🟢 |
| Redis 完全不可用 | 全部节点 | 🔴 |

### 容量规划

| 指标 | 当前 | 2027 预测 |
|------|------|----------|
| 内存使用 | 60% (19GB / 32GB) | 80% |
| QPS | 50K | 80K |
| 节点数 | 6 (3 主 3 从) | 12 |

---

## 🔗 相关

- [缓存策略 ADR](../architecture/adr/0005-permission-cache.md)
- [性能突降 Runbook](performance-degradation.md)
- [数据流 - 权限缓存](../architecture/data-flow.md#4-权限变更流程)
