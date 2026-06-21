# RB-009: 性能突降

> **等级**: 🟡 P1  
> **典型触发**: P99 延迟 > 1s（基线 300ms）或 QPS 下降 50%

---

## 🚨 立即确认

```bash
# 1. P99 延迟
curl -s 'https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket{job="user-service"}[5m]))'

# 2. QPS
curl -s 'https://prometheus.company.com/api/v1/query?query=sum(rate(http_requests_total{job="user-service"}[5m]))'

# 3. 慢请求
curl -s 'https://prometheus.company.com/api/v1/query?query=topk(10,histogram_quantile(0.99,rate(http_request_duration_seconds_bucket{job="user-service"}[5m]) by (path)))'
```

---

## 🛠 常见原因

### A. 缓存命中率下降

```bash
# 查 Redis 命中率
curl -s 'https://prometheus.company.com/api/v1/query?query=redis_keyspace_hit_rate'

# 看哪些 key 突然失效
redis-cli --bigkeys

# 修复：手动预热
kubectl exec -it <pod> -n user-service-prod -- \
  curl -X POST http://localhost:8000/admin/warm-cache
```

### B. DB 慢查询

详见 [api-error-rate-spike.md Step B](api-error-rate-spike.md#step-b-db-问题)

### C. 网络 / DNS

```bash
# 1. DNS 延迟
dig user.company.com

# 2. 网络抖动（pod 之间）
kubectl exec -it <pod> -n user-service-prod -- \
  ping -c 10 postgres-primary

# 3. 跨 AZ 流量
#    检查 service mesh 路由
```

### D. 资源不足

```bash
# 1. CPU
kubectl top pods -n user-service-prod

# 2. 内存
kubectl top pods -n user-service-prod

# 3. 临时扩容
kubectl scale deployment/user-service -n user-service-prod --replicas=20
```

### E. 下游变慢

```bash
# 看 P99 by service
curl -s 'https://prometheus.company.com/api/v1/query?query=topk(10,histogram_quantile(0.99,rate(http_request_duration_seconds_bucket{job=~"user-service|audit-service|notification-service"}[5m]) by (job)))'
```

---

## 📊 验证

- [ ] P99 < 300ms
- [ ] QPS 恢复
- [ ] 错误率 < 0.1%
- [ ] 缓存命中率 > 85%

---

## 🛡 长期改进

1. 容量压测（每季度）
2. 性能回归测试（CI 强制）
3. 自动扩容（HPA 调优）
4. 性能基线仪表盘
