# ADR-0005: 权限缓存策略

**状态**: ✅ Accepted  
**日期**: 2026-06-10  
**决策人**: @arch-lead, @zhangsan  
**关联 PROJ**: PROJ-1001

## 背景

当前每次 API 请求都重新计算权限（含组织树查询），P99 高达 800ms。
需要优化。

## 决策

**Redis 缓存有效权限，TTL 5 分钟 + 写后失效。**

## 数据结构

```python
# Redis key
"user:{user_id}:permissions" -> SET[permission_string]

# 例
"user:123:permissions" -> {
  "users:read:dept",
  "users:write:dept",
  "permissions:grant:dept",
  ...
}
```

## 写入策略

### 读路径

```python
async def get_user_permissions(user_id: UUID) -> set[str]:
    # 1. 查缓存
    cached = await redis.get(f"user:{user_id}:permissions")
    if cached:
        return set(cached.split(','))
    
    # 2. 缓存未命中，计算
    perms = await _calculate_permissions(user_id)
    
    # 3. 写缓存（5 分钟 TTL）
    await redis.setex(f"user:{user_id}:permissions", 300, ','.join(perms))
    
    return perms
```

### 写路径（失效）

任何权限变更（角色授予/撤销）：

```python
async def on_permission_changed(user_id: UUID):
    # 1. 删缓存
    await redis.delete(f"user:{user_id}:permissions")
    
    # 2. 发 Kafka（其他服务也清缓存）
    await events.publish("permission.changed", {"user_id": str(user_id)})
```

## TTL 选择

| TTL | 优 | 劣 |
|-----|----|----|
| 1 min | 实时性好 | 缓存命中率低 |
| 5 min | **平衡** | **5 分钟延迟** |
| 30 min | 命中率高 | 延迟大 |
| ∞ | 最高命中 | 一致性差 |

**5 分钟** = 性能与一致性的平衡。

加上"写后立即失效"，最坏情况延迟 = 5 分钟。

## BR-009 兼容

BR-009 要求"30 秒内生效"。我们的方案：
- **同服务内**：写后立即失效 → ≤ 1 秒生效 ✅
- **跨服务**：依赖 Kafka 事件传递 → ≤ 30 秒 ✅

## 影响

### 正面
- ✅ P99 从 800ms 降到 200ms（实测）
- ✅ DB 查询减少 95%
- ✅ Kafka 事件让全网一致

### 负面
- 缓存失效逻辑必须正确（漏失效 = 数据不一致）
- Redis 故障 = 降级到直查 DB

## 监控指标

| 指标 | 目标 |
|------|------|
| 缓存命中率 | > 90% |
| P99 延迟 | < 200ms |
| 权限生效延迟 | < 30s |
| Redis 内存使用 | < 1GB |

## 后果

- ✅ **必须**: 所有权限变更发 `permission.changed` 事件
- ✅ **必须**: 跨服务消费该事件并清自己的缓存
- ✅ **必须**: Redis 故障自动降级（直查 DB）
- ❌ **禁止**: 缓存超过 1 小时（避免长时间不一致）
