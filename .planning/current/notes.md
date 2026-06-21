# 调研笔记: 用户登录 P99 优化 [PROJ-1001]

> 复制此模板替换为自己的调研笔记。

---

## 现状分析 (Current State)

### Profile 数据（2026-06-21 14:00 采样）

| 阶段 | 耗时 | 占比 |
|------|------|------|
| JWT 验签 | 3ms | 0.4% |
| 查询 user (DB) | 350ms | 44% 🔴 |
| 查询 permissions (DB + JOIN) | 420ms | 52% 🔴🔴 |
| 组装响应 | 25ms | 3% |
| **总 P99** | **800ms** | - |

**核心瓶颈**：DB 查询占 96%，其中 permissions 查询最严重（5 张表 JOIN）。

### 当前架构

```
Request → JWT verify → User.query → Permissions.compute → Response
              3ms          350ms            420ms            25ms
```

## 调研发现 (Findings)

### 2026-06-21 14:30 — Profile 结果分析

- **做什么**: 用 py-spy record 10 分钟生产流量
- **结果**: 95% 时间花在 DB
- **影响**: 任何 DB 优化都能显著改善 P99

### 2026-06-21 14:50 — 现存缓存检查

- **做什么**: grep "redis\|cache" src/
- **结果**: 只有 session 用了 Redis，user/permissions 完全没缓存
- **影响**: 每次请求都直查 DB

### 2026-06-21 15:10 — 用户访问模式

- **做什么**: 分析日志看同一用户的请求频率
- **结果**: 80% 用户每天访问 < 10 次，但 20% 高频用户每天 50+ 次
- **影响**: 缓存高频用户可显著降低 DB 压力

## 失败的尝试 (Failed Attempts)

### ❌ 试过 JWT claims 带 permissions

- **时间**: 2026-06-15（前期调研）
- **做了什么**: 在 JWT payload 里加 permissions 数组
- **为什么失败**:
  - JWT 增大 ~500 bytes，影响每个请求
  - 撤销复杂（必须等 JWT 过期）
  - 跟现有 SSO 集成冲突
- **教训**: 不在 JWT 里塞业务数据

## 参考资料 (References)

- Redis 缓存模式：https://redis.io/docs/manual/client-side-caching/
- BR-009 业务规则：`docs/requirements/business-rules.md`
- ADR-0003 JWT 决策：`docs/architecture/adr/0003-jwt-vs-session.md`

## 待确认问题 (Open Questions)

- [ ] 缓存 TTL 是否要按用户分层？（高频 vs 低频）
- [ ] 权限变更事件从哪个服务发？（HR 系统 vs 本服务）

## 灵感 (Ideas)

- 💡 未来：考虑用 Redis Streams 替代 Kafka（场景更轻量）
- 💡 未来：权限计算放 ClickHouse 做 OLAP（如果用户量大到 Redis 不够）
