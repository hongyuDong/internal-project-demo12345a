# 系统架构总览

> **最后更新**: 2026-06-21  
> **Owner**: @arch-team

---

## 1. 定位

`internal-user-service` 是公司**内部统一的身份与权限管理服务**，所有内部系统通过它管理员工、组织、权限。

```
┌─────────────────────────────────────────────────────────┐
│                    公司内部应用                           │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐      │
│   │ HR 系统 │ │ 报销系统 │ │ 文档平台 │ │ 研发平台 │ ... │
│   └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘      │
│        │           │           │           │            │
│        └───────────┴───────────┴───────────┘            │
│                          │                               │
│                          │ REST / gRPC                   │
│                          ▼                               │
│        ┌─────────────────────────────────────┐          │
│        │      user-service (本服务)          │          │
│        │      identity & permission hub      │          │
│        └─────────────────────────────────────┘          │
│                          │                               │
└──────────────────────────┼──────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │PostgreSQL│ │  Redis   │ │  Kafka   │
        └──────────┘ └──────────┘ └──────────┘
```

## 2. 架构风格

**领域驱动设计 (DDD) + 六边形架构 + 事件驱动**

- **核心域**: 用户、组织、权限
- **支撑域**: 审计、通知
- **通用域**: 通用库、监控

## 3. 分层架构

```
┌──────────────────────────────────────────────────┐
│            API Layer (FastAPI Router)            │  ← 接入层
├──────────────────────────────────────────────────┤
│         Application Layer (Use Cases)            │  ← 应用层
├──────────────────────────────────────────────────┤
│           Domain Layer (Business Logic)          │  ← 领域层
├──────────────────────────────────────────────────┤
│     Infrastructure Layer (DB / Cache / MQ)       │  ← 基础设施
└──────────────────────────────────────────────────┘
```

对应代码目录：

```
src/
├── api/v1/              # API Layer
├── services/            # Application Layer
├── core/                # Domain Layer (entities, services)
├── repositories/        # Infrastructure (DB)
├── events/              # Infrastructure (MQ)
└── utils/               # 通用工具
```

## 4. 技术选型

| 维度 | 选型 | 理由 | ADR |
|------|------|------|-----|
| 语言 | Python 3.11+ | 团队熟练度高、生态丰富 | - |
| Web 框架 | FastAPI | async 原生 + 自动 OpenAPI | - |
| ORM | SQLAlchemy 2.0 | 成熟、async 支持 | - |
| 数据库 | PostgreSQL 15 | 公司规范 + JSONB + 全文搜索 | [ADR-0001](adr/0001-why-postgresql.md) |
| 缓存 | Redis 7 | 高性能 + 多种数据结构 | [ADR-0002](adr/0002-why-event-driven.md) |
| 消息队列 | Kafka | 公司规范 + 高吞吐 | [ADR-0002](adr/0002-why-event-driven.md) |
| 认证 | JWT (RS256) | 无状态 + 易扩展 | [ADR-0003](adr/0003-jwt-vs-session.md) |
| 部署 | Kubernetes | 公司标准 | - |
| 监控 | Prometheus + Grafana | 公司标准 | - |
| 日志 | structlog → ELK | 公司标准 | - |
| 链路追踪 | OpenTelemetry | 公司标准 | - |

## 5. 数据架构

### 5.1 主存储（PostgreSQL）

| 表 | 行数估算 | 增长率 |
|----|----------|--------|
| `users` | 5000 万 | +5%/年 |
| `organizations` | 5 万 | +0.5%/年 |
| `roles` | < 100 | 几乎不变 |
| `permissions` | < 1000 | +10/年 |
| `user_roles` | 1 亿 | +5%/年 |
| `user_audit_log` | 100 亿 | +10 亿/年 |

### 5.2 缓存（Redis）

| Key 模式 | 内容 | TTL |
|----------|------|-----|
| `user:{id}` | 用户基本信息 | 5 min |
| `user:{id}:permissions` | 有效权限集合 | 5 min |
| `session:{session_id}` | 会话信息 | 1 h |
| `token:blacklist:{jti}` | 撤销的 JWT | 24 h |
| `rate_limit:{user_id}:{window}` | API 调用计数 | 1 min |

### 5.3 事件流（Kafka）

| Topic | 分区数 | 保留期 | 消费者 |
|-------|--------|--------|--------|
| `user.created` | 12 | 7 天 | 8 个服务 |
| `user.updated` | 12 | 7 天 | 5 个服务 |
| `user.deleted` | 12 | 30 天 | 3 个服务 |
| `user.deactivated` | 12 | 90 天 | 所有依赖 |
| `organization.tree_restructure` | 3 | 30 天 | 2 个服务 |
| `audit.events` | 12 | 7 年 | audit-service |
| `notification.requested` | 6 | 1 天 | notification-service |

## 6. 部署架构

### 6.1 K8s 拓扑

```
Namespace: user-service-prod
├── Deployment: user-service (3-20 replicas, HPA)
├── Service: user-service (ClusterIP)
├── Ingress: user.company.com (TLS via cert-manager)
├── ConfigMap: config
├── Secret: db-password, vault-token (from external-secrets)
├── HPA: cpu 60%, memory 70%
├── PDB: minAvailable 1
└── NetworkPolicy: 限制入站来源
```

### 6.2 多环境

| 环境 | 用途 | 数据 |
|------|------|------|
| `local` | 开发 | docker-compose |
| `dev` | 集成测试 | fake data |
| `staging` | 预发布 | 生产数据脱敏 |
| `prod` | 生产 | 真实数据 |

详见 `docs/architecture/deployment.md`

## 7. 安全架构

### 7.1 纵深防御

```
外部请求
    ↓
[WAF / Rate Limit]              ← L7 防护
    ↓
[TLS Termination]               ← 加密传输
    ↓
[API Gateway]                   ← 鉴权 / 限流
    ↓
[mTLS between services]         ← 服务间加密
    ↓
[App-level Auth (JWT verify)]   ← 应用层鉴权
    ↓
[Permission Check (RBAC)]       ← 授权
    ↓
[PII Encryption at Rest]        ← 数据加密
    ↓
[Audit Log]                     ← 审计
```

### 7.2 密钥管理

- 所有密钥从 **HashiCorp Vault** 读取
- K8s 通过 External Secrets Operator 同步
- **永不在代码 / 环境变量中硬编码**

### 7.3 威胁建模

| 威胁 | 缓解措施 |
|------|----------|
| SQL 注入 | SQLAlchemy 参数化 + Code review |
| XSS | React 自动转义 + CSP header |
| CSRF | SameSite=Strict Cookie + Token |
| 越权访问 | RBAC 中间件 + ownership 检查 |
| 数据泄漏 | PII 加密 + 访问审计 + DLP |
| DDoS | Rate limit + WAF |
| 内部威胁 | 全链路审计 + 最小权限 |

## 8. 可观测性

### 8.1 三大支柱

| 维度 | 工具 | 指标 |
|------|------|------|
| **Metrics** | Prometheus | 请求量、延迟、错误率、QPS、CPU/Mem |
| **Logs** | structlog → ELK | 结构化日志 + trace_id |
| **Traces** | OpenTelemetry | 跨服务调用链 |

### 8.2 SLO

| 服务 | SLI | SLO |
|------|-----|-----|
| API 可用性 | 成功请求 / 总请求 | ≥ 99.95% |
| API 延迟 | P99 | < 300ms |
| 入职到可用 | 端到端时间 | < 5 min |

## 9. 演进路径

```
┌────────────────────────────────────────────────────┐
│ 当前 (2026)         │ 未来 (2027)                 │
├─────────────────────┼─────────────────────────────┤
│ 单区域单活          │ 多区域多活                   │
│ 同步 DB 复制        │ 异步 + Binlog                │
│ 单 Kafka 集群        │ MirrorMaker 2 跨区同步       │
│ 手动扩缩容          │ KEDA 事件驱动               │
│ 日志 ELK           │ OpenObserve (省钱)           │
└─────────────────────┴─────────────────────────────┘
```

## 10. 关联文档

- [数据流](data-flow.md)
- [部署架构](deployment.md)
- [外部集成](integrations.md)
- [ADR 列表](adr/)
