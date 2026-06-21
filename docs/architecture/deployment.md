# 部署架构

> **最后更新**: 2026-06-21

---

## 1. 环境分层

| 环境 | 用途 | 数据 | 流量 | 谁可以部署 |
|------|------|------|------|----------|
| `local` | 开发者本机 | docker-compose + fake data | - | 开发者自己 |
| `dev` | 共享 dev | fake data | 测试流量 | 任何人（CI 自动） |
| `staging` | 预发布 | 生产数据**脱敏** | 内部测试 | 合并到 main 后自动 |
| `prod` | 生产 | 真实数据 | 真实流量 | EM/Tech Lead + release 流程 |

## 2. K8s 拓扑

### 2.1 Namespace 结构

```
prod:
├── user-service-prod         # 主服务
│   ├── Deployment (3-20 replicas)
│   ├── Service (ClusterIP)
│   ├── Ingress (user.company.com)
│   ├── HPA
│   ├── PDB
│   ├── NetworkPolicy
│   └── ServiceAccount
├── shared-infra              # 共享基础设施
│   ├── postgres (statefulset, 3 replicas)
│   ├── redis (statefulset, 6 nodes)
│   ├── kafka (statefulset, 5 brokers)
│   └── vault (statefulset, HA)
└── monitoring
    ├── prometheus
    ├── grafana
    └── alertmanager
```

### 2.2 Deployment 规范

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: user-service-prod
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0  # 零停机
  template:
    spec:
      containers:
      - name: user-service
        image: registry.company.com/user-service:v1.4.2
        ports:
        - containerPort: 8000
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 2000m
            memory: 2Gi
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8000
          periodSeconds: 5
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8000
          periodSeconds: 10
          failureThreshold: 3
        env:
        - name: ENV
          value: "prod"
        envFrom:
        - secretRef:
            name: user-service-secrets  # 来自 Vault
```

### 2.3 HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service
spec:
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
```

## 3. CI/CD 流程

### 3.1 Pipeline

```
PR 提交
  ↓
[CI] Lint + Type Check
  ↓
[CI] Unit Tests
  ↓
[CI] Build Docker image
  ↓
[CI] Integration Tests (against staging)
  ↓
PR Review (≥1 approver)
  ↓
Merge to main
  ↓
[CD] Deploy to dev (auto)
  ↓
[CD] Deploy to staging (auto, on tag)
  ↓
[Manual] Deploy to prod (release command)
```

### 3.2 部署窗口

- **dev / staging**: 任何时间自动部署
- **prod**: 工作日 10:00-16:00（紧急 P0 修复可破例）

### 3.3 紧急 hotfix 流程

```bash
# 1. 从 main 拉 hotfix 分支
git checkout main && git checkout -b hotfix/PROJ-XXXX

# 2. 修代码（最小修改）

# 3. PR + 2 approver（必须 EM + SRE Lead）

# 4. 合并后自动部署到 prod（跳过 staging）

# 5. 24h 监控
```

## 4. 数据库部署

### 4.1 Migration 策略

```bash
# 在 staging 跑（自动）
make db-migrate-staging MSG="add_phone_encryption"

# 在 prod 跑（手动，需审批）
make db-migrate-prod MSG="add_phone_encryption"
```

### 4.2 大表 DDL 规则

| 操作 | 是否允许 | 工具 |
|------|----------|------|
| 加列（nullable） | ✅ | `ALTER TABLE ADD COLUMN` |
| 加列（NOT NULL） | ❌ 单步 | 必须分 2 步 |
| 加索引 | ✅ 必须 CONCURRENTLY | `CREATE INDEX CONCURRENTLY` |
| 删列 | ❌ | 软删 + 30 天 + DBA 审批 |
| 改类型 | ❌ | expand-migrate-contract |

详见 `docs/architecture/adr/0006-migration-strategy.md`（待补）

## 5. 监控 / 告警

### 5.1 关键告警

| 级别 | 触发条件 | 通知 |
|------|----------|------|
| **P0** | 服务挂 / 数据丢失 / 安全事件 | 电话 + Slack + PagerDuty |
| **P1** | 错误率 > 1% / P99 > 2s | Slack + PagerDuty |
| **P2** | 错误率 > 0.1% / P99 > 500ms | Slack |
| **P3** | 资源使用率高 | Slack（每日汇总） |

### 5.2 关键仪表盘

- 服务总览：`https://grafana.company.com/d/user-service`
- DB 详情：`https://grafana.company.com/d/user-service-db`
- Kafka lag：`https://grafana.company.com/d/kafka`

## 6. 灾备 (DR)

### 6.1 备份策略

| 数据 | 频率 | 保留 | 存储 |
|------|------|------|------|
| Postgres 全量 | 每日 03:00 | 30 天 | S3 + 异地 |
| Postgres 增量 | 每 15 分钟 | 7 天 | S3 |
| Redis | 不备份（可重建） | - | - |
| Kafka | 7 天（业务）/ 7 年（审计） | 按 topic | - |

### 6.2 恢复时间

| 场景 | RTO | RPO |
|------|-----|-----|
| 单 Pod 故障 | < 1 min | 0 |
| AZ 故障 | < 5 min | 0 |
| Region 故障 | < 30 min | < 15 min |
| 数据损坏 | < 2 h | < 15 min |

### 6.3 DR 演练

- 季度一次
- 故意 kill 主节点，验证切换
- 记录时间 + 改进项

## 7. 容量规划

### 7.1 当前（2026-06）

| 资源 | 当前使用 | 上限 | 余量 |
|------|----------|------|------|
| CPU | 30% | 100% | 3.3x |
| 内存 | 45% | 100% | 2.2x |
| DB 连接 | 50/100 | 100 | 2x |
| Kafka lag | 0.5s | 30s | 60x |

### 7.2 增长预测

| 指标 | 当前 | 1 年后 | 2 年后 |
|------|------|--------|--------|
| 用户数 | 5000 万 | 5500 万 | 6000 万 |
| QPS | 5000 | 6000 | 7000 |
| 数据量 | 2 TB | 2.5 TB | 3 TB |

扩容策略：HPA 自动 + 季度手动 review
