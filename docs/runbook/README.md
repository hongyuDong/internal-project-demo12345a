# Runbook 总览

> 事故应急手册。所有 on-call 必读。
> 模板来自 `docs/project/postmortems/template.md`

---

## 🚨 响应流程（4 步）

```
1. 收到告警（PagerDuty / Slack）
   ↓
2. 5 分钟内确认事故等级 + 开频道 #inc-XXXX
   ↓
3. 按本 Runbook 执行缓解
   ↓
4. 24-48 小时内写 postmortem
```

---

## 📚 事故 Runbook 索引

| 编号 | 场景 | 等级 | 文件 |
|------|------|------|------|
| RB-001 | API 错误率飙升 | 🟡 P1 | [api-error-rate-spike.md](api-error-rate-spike.md) |
| RB-002 | 数据库主库故障 | 🔴 P0 | [db-primary-failure.md](db-primary-failure.md) |
| RB-003 | Redis 宕机 | 🟡 P1 | [redis-down.md](redis-down.md) |
| RB-004 | Kafka 消费积压 | 🟡 P1 | [kafka-lag.md](kafka-lag.md) |
| RB-005 | 用户无法登录 | 🔴 P0 | [login-failure.md](login-failure.md) |
| RB-006 | 缓存污染 | 🟡 P1 | [cache-poisoning.md](cache-poisoning.md) |
| RB-007 | 数据损坏 / 不一致 | 🔴 P0 | [data-corruption.md](data-corruption.md) |
| RB-008 | 安全事件 | 🔴 P0 | [security-incident.md](security-incident.md) |
| RB-009 | 性能突降 | 🟡 P1 | [performance-degradation.md](performance-degradation.md) |
| RB-010 | 第三方依赖故障 | 🟡 P1 | [third-party-outage.md](third-party-outage.md) |

---

## 🔧 通用工具

### 紧急联系

| 角色 | 联系方式 |
|------|----------|
| On-call 工程师 | PagerDuty |
| EM | @em, 13800000001 |
| SRE Lead | @sre-lead, 13800000002 |
| DBA | @dba, 13800000003 |
| Security | @security, 13800000004 |

### 应急命令（预装在 K8s pod 里）

```bash
# 查看服务状态
kubectl get pods -n user-service-prod
kubectl top pods -n user-service-prod

# 看实时日志
kubectl logs -f -n user-service-prod -l app=user-service

# 进 pod 调试（生产慎用！）
kubectl exec -it <pod-name> -n user-service-prod -- /bin/bash

# 重启所有 pod
kubectl rollout restart deployment/user-service -n user-service-prod

# 扩容
kubectl scale deployment/user-service -n user-service-prod --replicas=20

# 回滚
kubectl rollout undo deployment/user-service -n user-service-prod
kubectl rollout history deployment/user-service -n user-service-prod

# 数据库紧急查询
kubectl exec -it postgres-primary-0 -n user-service-prod -- psql -U admin -d users
```

### 应急开关 (Feature Flags)

```bash
# 通过 LaunchDarkly CLI
ld flag set user-service.maintenance-mode --enabled true
ld flag set user-service.readonly-mode --enabled true
ld flag set user-service.cache-bypass --enabled true
```

---

## 🎯 事故等级速查

| 信号 | 等级 |
|------|------|
| 服务挂 / 数据丢失 / 安全事件 | 🔴 P0 |
| 核心功能受损 / 错误率 > 1% / P99 > 2s | 🟡 P1 |
| 非核心功能受损 / 错误率 > 0.1% | 🟢 P2 |
| 小 bug / 文案错误 | ⚪ P3 |

---

## 🛑 通用禁止

| ❌ 永远不要 | 原因 |
|-----------|------|
| 未经 IC 同意改代码 | 可能加剧事故 |
| 在生产直连 DB 改数据 | 绕过审计 |
| 删除 Kafka topic | 数据丢失 |
| 强删 S3 备份 | 失去恢复能力 |
| 在 #announce 发未确认消息 | 引起恐慌 |

---

## 📊 事故状态页

更新 `https://status.company.com/user-service`：

- **正常**: 绿色
- **降级**: 黄色 + 说明
- **中断**: 红色 + 预计恢复时间

---

## 📞 升级路径

```
P3 / P2:  on-call 工程师处理
P1:       on-call + Tech Lead, 30 分钟内
P0:       on-call + Tech Lead + EM + SRE Lead, 立即
          + 通知全公司 #announcements
          + 启动 incident 频道
```

---

## 🔗 相关文档

- [Postmortem 模板](../project/postmortems/template.md)
- [架构总览](../architecture/overview.md)
- [部署架构](../architecture/deployment.md)
- [告警规则](https://alertmanager.company.com)
- [Grafana 仪表盘](https://grafana.company.com/d/user-service)
