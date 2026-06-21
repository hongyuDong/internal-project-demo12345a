# 数据流图 (Data Flow)

> **最后更新**: 2026-06-21

---

## 1. 用户登录流程

```
用户 → 浏览器 → SSO → user-service → Redis (session)
                       ↓
                    Postgres (user)
                       ↓
                    计算 permissions
                       ↓
                    Redis (perms cache)
                       ↓
                    返回 JWT
                       ↓
                    用户 (cookie)
                       ↓
                    浏览器发起 API 请求
                       ↓
                    user-service 验证 JWT
                       ↓
                    检查 permissions
                       ↓
                    返回数据
```

## 2. 用户创建流程（含审计 + 事件广播）

```
HR 系统
  │
  │ POST /v1/users (或发 user.import.requested Kafka)
  ▼
user-service API 层
  │
  │ 验证 JWT + 权限
  ▼
Service 层 (CreateUser)
  │
  ├─→ 1. 业务校验（BR-001, BR-002, BR-006）
  │
  ├─→ 2. 加密 PII（BR-011）
  │
  ├─→ 3. INSERT into users
  │
  ├─→ 4. INSERT into user_roles (默认 employee)
  │
  ├─→ 5. 写审计日志（HMAC 签名）
  │
  ├─→ 6. 发布 Kafka event: user.created
  │     {
  │       "event_id": "...",
  │       "user_id": "...",
  │       "email": "...",
  │       "department_id": "...",
  │       "actor_id": "..."  # 谁创建的
  │     }
  │
  ▼
返回 201 + Location
```

**下游订阅者**：
- notification-service → 发欢迎邮件
- audit-service → 入审计库
- 8 个其他服务 → 同步用户数据到本地 cache

## 3. 离职流程（即时失效）

```
HR 系统
  │
  │ POST /v1/users/{id}/deactivate
  ▼
user-service
  │
  ├─→ 1. 验证 actor 是 HR / Admin
  │
  ├─→ 2. UPDATE users SET status='disabled', deactivated_at=NOW()
  │
  ├─→ 3. 撤销所有 session（写 Redis blacklist）
  │
  ├─→ 4. 撤销所有 token（jti 进 blacklist）
  │
  ├─→ 5. 写审计日志
  │
  ├─→ 6. 发布 Kafka: user.deactivated
  │
  ▼
所有依赖服务消费事件
  │
  ├─→ 立即禁用该用户的所有 session
  ├─→ 清理本地缓存
  └─→ 通知相关方
```

**SLO**: ≤ 10 秒内全网生效

## 4. 权限变更流程

```
Admin
  │
  │ POST /v1/users/{id}/roles
  ▼
user-service
  │
  ├─→ 1. 验证 actor 是 admin
  │
  ├─→ 2. INSERT into user_roles
  │
  ├─→ 3. 删除 Redis 权限缓存（user:{id}:permissions）
  │
  ├─→ 4. 写审计日志
  │
  ├─→ 5. 发布 Kafka: permission.granted
  │
  ▼
下次 API 调用（≤ 30 秒）：
  │
  ├─→ user-service 查 DB 计算新权限
  ├─→ 写回 Redis
  └─→ 返回
```

## 5. 转部门流程（异步 + Grace Period）

```
HR 系统
  │
  │ 发 user.transfer.requested Kafka
  ▼
user-service 消费
  │
  ├─→ 1. UPDATE users SET primary_department_id = new_dept, transfer_old_dept_until = NOW() + 7d
  │
  ├─→ 2. 保留旧部门权限 7 天（写 user_secondary_departments）
  │
  ├─→ 3. 写审计
  │
  ├─→ 4. 发布 user.organization_changed
  │
  ▼
7 天后（定时任务）：
  │
  ├─→ 删除旧部门关联
  ├─→ 发布 user.organization_change_completed
  └─→ 写审计
```

## 6. 批量导入流程（异步任务）

```
Admin
  │
  │ POST /v1/users/bulk-import (CSV file, ≤ 10000 rows)
  ▼
user-service
  │
  ├─→ 1. 校验 CSV 格式
  │
  ├─→ 2. 写 import job 到 DB（status=pending）
  │
  ├─→ 3. 发布 task.import.requested
  │
  ▼
Background worker（消费 task.import.requested）
  │
  ├─→ 逐行处理
  │     ├─→ 校验每行
  │     ├─→ 成功 → 写 DB
  │     ├─→ 失败 → 写 dead_letter
  │     └─→ 每行发 user.created 事件
  │
  ├─→ 完成后更新 job 状态
  │
  ▼
Admin 轮询 GET /v1/jobs/{id} 或订阅 WebSocket
```

---

## 关键设计决策

| 决策 | 理由 |
|------|------|
| **事件驱动** | 解耦下游，雪崩保护 |
| **同步路径写入 + 异步事件** | 写后立即可读（强一致），事件最终一致 |
| **缓存失效而非更新** | 避免并发写覆盖，简化逻辑 |
| **权限 5 分钟 TTL** | 平衡性能 + 实时性 |
| **审计 HMAC 签名** | 防篡改 + 法律证据 |

## 异常处理

| 异常 | 行为 |
|------|------|
| DB 写成功但 Kafka 失败 | Outbox 模式，定时重试 |
| Kafka 写成功但 DB 失败 | 消费者看到但查不到用户，告警 + 自动补偿 |
| Redis 故障 | 降级到直查 DB（性能降级但不挂） |
| 下游消费失败 | 重试 3 次 + dead letter + 告警 |
