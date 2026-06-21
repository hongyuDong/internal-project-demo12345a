# 外部集成 (Integrations)

> **最后更新**: 2026-06-21  
> **集成数**: 8 个下游 + 3 个上游 + 2 个内部

---

## 上游服务（被依赖 / 调用本服务）

### HR 系统 (`hr-system`)

- **协议**: REST + Kafka
- **作用**: 员工入职 / 转岗 / 离职
- **API**:
  - `POST /v1/users/batch-import` (CSV)
  - `POST /v1/users/{id}/deactivate`
- **Kafka 消费**:
  - `user.transfer.requested`
  - `user.offboard.requested`
- **认证**: mTLS + API Key
- **SLA**: HR 系统调本服务 P99 < 500ms

### SSO 服务 (`sso.company.com`)

- **协议**: SAML 2.0
- **作用**: 唯一认证入口
- **验证**: 本服务所有 API 必须接受 SSO 颁发的 JWT
- **不直接调用**：HR 系统代为完成 token 交换

### IdP / LDAP (`ldap.company.com`)

- **协议**: LDAP
- **作用**: 组织 / 员工数据源头
- **同步**: HR 系统定期同步，本服务实时查询（缓存）

## 下游服务（依赖本服务的事件）

### notification-service

- **Kafka 消费**:
  - `user.created` → 发欢迎邮件
  - `user.deactivated` → 发离职通知
  - `user.organization_changed` → 通知相关方
- **本服务提供**: 事件 payload + REST 查询

### audit-service

- **Kafka 消费**: `audit.events`（所有事件汇总）
- **存储**: 长期合规留存（7 年）

### downstream-cache-1..8

- **8 个内部服务**消费 `user.*` 事件同步本地缓存
- **示例**: hr-portal, expense-system, doc-platform, dev-platform, ...

## 内部基础设施

### PostgreSQL 主库

- **库名**: `users_prod`
- **连接**: 通过 PgBouncer (pool 模式)
- **凭据**: 从 Vault 读取

### Redis 集群

- **用途**: session / 权限缓存 / 限流 / 分布式锁
- **集群**: 6 节点（3 主 3 从）
- **内存**: 32GB / 节点

### Kafka 集群

- **用途**: 事件流
- **集群**: 5 节点（跨 3 AZ）
- **Topic 数**: 12 个
- **保留**: 默认 7 天，audit 7 年

### HashiCorp Vault

- **用途**: 密钥管理
- **集成**: K8s External Secrets Operator
- **路径**: `secret/user-service/*`

## 第三方 SaaS

### Datadog

- **用途**: APM + 日志聚合 + 告警
- **集成**: DD Agent sidecar
- **数据**: 100% 流量采样（采样率可调）

### PagerDuty

- **用途**: P0/P1 事故告警
- **集成**: Webhook + Alertmanager
- **升级策略**: 主 → 备 → EM

### LaunchDarkly

- **用途**: Feature flags
- **集成**: Server-side SDK
- **项目 key**: `user-service`

## API 契约

### REST

OpenAPI 3.1 spec：`docs/api/openapi.yaml`（待补）

### gRPC

Proto 定义：`src/proto/user_service.proto`（未来）

### Kafka 事件

Schema：`docs/events/*.avsc`（待补）

## SLA 与故障转移

| 集成 | 故障影响 | 缓解 |
|------|----------|------|
| HR 系统 | 入职延迟 | 重试 + 死信队列 |
| SSO | 所有人无法登录 | Cache + 限流降级 |
| Kafka | 事件丢失 | Outbox 模式 + 重试 |
| Redis | 性能降级 | 直查 DB fallback |
| Postgres | 全服务不可用 | 主从切换 + 告警 |
| Vault | 启动失败 | K8s 健康检查失败不启动 |

## 集成测试

每个集成必须有：
- [ ] 单元测试（mock 集成）
- [ ] 集成测试（staging 真集成）
- [ ] 混沌测试（注入故障）
- [ ] 容量测试（峰值流量）

测试在 `tests/integration/integrations/`
