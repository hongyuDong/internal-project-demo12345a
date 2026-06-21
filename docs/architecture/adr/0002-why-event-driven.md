# ADR-0002: 选择 Kafka 作为消息队列 + 事件驱动架构

**状态**: ✅ Accepted  
**日期**: 2025-09-01  
**决策人**: @arch-lead, @sre-lead  
**被替代**: 无（首版决策）

## 背景

新服务需要：
1. 同步通知多个下游（user.created → 8 个服务）
2. 数据变更审计
3. 跨服务数据同步

如果用同步 REST 调用：
- 强耦合（user-service 知道所有下游）
- 雪崩风险（下游慢 → 整个链路慢）
- 事务复杂（分布式事务）

## 决策

采用**事件驱动架构 + Kafka**：
- 所有数据变更发 Kafka 事件
- 下游服务订阅消费
- user-service 不直接调用下游

## 事件 Schema

```json
{
  "event_id": "uuid",
  "event_type": "user.created",
  "event_time": "2026-06-21T12:00:00Z",
  "schema_version": "1.0",
  "producer": "user-service",
  "trace_id": "abc123",
  "payload": {
    "user_id": "uuid",
    "email": "...",
    ...
  }
}
```

## Topic 设计

| 命名 | 例子 |
|------|------|
| `{resource}.{action}` | `user.created`, `user.updated`, `organization.deleted` |
| 过去式 | `created` 而不是 `create`（强调已发生） |

## 顺序保证

**同 `user_id` 的事件必须同 partition**：
- key = `user_id` 字符串
- 12 个 partition

保证：单个用户的事件顺序一致；不同用户并行处理。

## 可靠性

- `acks=all`：等所有副本确认
- `min.insync.replicas=2`
- Producer 端重试 3 次

## 影响

### 正面
- ✅ 完全解耦：user-service 不知道下游存在
- ✅ 高可用：Kafka 故障不影响主流程
- ✅ 可重放：新服务可消费历史事件
- ✅ 天然审计：所有事件都进 Kafka 留存

### 负面
- 调试复杂（分布式追踪必需）
- 事件顺序保证有限（仅同 key）

## 后果

- ✅ **必须**: 所有数据变更发事件
- ✅ **必须**: 事件 payload 包含 `event_id` 用于去重
- ✅ **必须**: 消费者实现幂等
- ❌ **禁止**: 业务逻辑直接调用下游服务 REST API
- ⚠️ **注意**: 事件 schema 变更要兼容旧版本

## 验证

- ✅ 已用于生产 1 年，处理 10 亿+ 事件
- ✅ 峰值 50000 events/s，无延迟
- ✅ 下游服务故障不影响主流程
