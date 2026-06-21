# RB-006: 缓存污染

> **等级**: 🟡 P1（影响安全/正确性 → 🔴 P0）  
> **典型触发**: 缓存中的数据与 DB 不一致，或缓存含陈旧/错误数据

---

## 🚨 立即确认

```bash
# 1. 抽样对比（Redis vs DB）
for user_id in $(seq 1 100); do
  redis_val=$(redis-cli get "user:$user_id")
  db_val=$(psql -t -c "SELECT email FROM users WHERE id = $user_id")
  if [ "$redis_val" != "$db_val" ]; then
    echo "MISMATCH: user:$user_id"
  fi
done

# 2. 看 cache-bypass 模式是否启用
ld flag get user-service.cache-bypass
```

---

## 🛠 修复

### A. 全部清空（最暴力）

```bash
# 清所有用户权限缓存
redis-cli --scan --pattern "user:*:permissions" | xargs redis-cli del

# 清所有用户基本信息
redis-cli --scan --pattern "user:*" --exclude "*permissions*" | xargs redis-cli del

# 触发主动预热
kubectl exec -it <pod> -n user-service-prod -- \
  curl -X POST http://localhost:8000/admin/warm-cache
```

### B. 选择性清空（已知错误 key）

```bash
# 单个 key
redis-cli del "user:12345:permissions"

# 某个 user_id 范围
for id in $(seq 1000 2000); do
  redis-cli del "user:$id"
  redis-cli del "user:$id:permissions"
done
```

### C. 临时禁用缓存

```bash
# 直查 DB（性能降级但正确）
ld flag set user-service.cache-bypass --enabled true

# 等问题修复后关闭
ld flag set user-service.cache-bypass --enabled false
```

---

## 🔍 根因分析

| 根因 | 检查方法 |
|------|----------|
| 写后失效逻辑漏了 | 检查代码路径 |
| TTL 太长 | 看 `user:*:permissions` TTL |
| 数据迁移期间不同步 | 看最近部署/迁移 |
| Redis 内存满自动淘汰 | `redis-cli info stats` 看 evicted_keys |

---

## 🛡 长期改进

1. **监控告警**: Redis 和 DB 数据不一致率 > 0.1% 告警
2. **写后失效**: 强校验（不只是 DEL，还要 SET null 然后 DEL）
3. **定期校对**: 每天凌晨低峰跑一致性检查脚本
4. **降级开关**: cache-bypass 必须 < 30s 生效
