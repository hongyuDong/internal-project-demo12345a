# RB-002: 数据库主库故障

> **等级**: 🔴 P0  
> **典型触发**: 主库不可达 / 数据损坏 / 复制中断  
> **响应时间**: 立即

---

## 🚨 立即确认（2 分钟内）

```bash
# 1. 主库是否可达
kubectl exec -it postgres-primary-0 -n user-service-prod -- pg_isready
# 期望: accepting connections

# 2. 主从复制状态（从库）
kubectl exec -it postgres-replica-0 -n user-service-prod -- psql -U admin -d users -c "
SELECT client_addr, state, sync_state, sent_lsn, replay_lsn
FROM pg_stat_replication;
"

# 3. 看主库日志
kubectl logs -n user-service-prod postgres-primary-0 --tail=50
```

---

## 🛠 常见场景

### A. 主库崩溃（Pod 不可用）

**症状**: `pg_isready` 失败

**修复**:
```bash
# 1. 看 pod 状态
kubectl get pod postgres-primary-0 -n user-service-prod
kubectl describe pod postgres-primary-0 -n user-service-prod

# 2. 常见原因
#    - OOMKilled → 增加内存
#    - Node lost → 节点恢复后自动回来
#    - 存储故障 → 见下方

# 3. 如果 StatefulSet 自动恢复失败
kubectl delete pod postgres-primary-0 -n user-service-prod
# 会自动重建（数据在 PVC 里）
```

### B. 存储故障（PVC 损坏）

**症状**: pod 起不来，volume mount 失败

**修复**:
```bash
# 1. 看 PV/PVC 状态
kubectl get pv,pvc -n user-service-prod | grep postgres

# 2. 看存储后端（Ceph / EBS / ...）
#    找 SRE 协助

# 3. 如果 PV 数据损坏
#    - 启动备用集群（如果有）
#    - 从最新备份恢复（见下方）
```

### C. 复制中断 / 主从延迟过大

**症状**: `replay_lsn` 落后 `sent_lsn` 太多

**修复**:
```bash
# 1. 看延迟
kubectl exec -it postgres-replica-0 -n user-service-prod -- psql -U admin -d users -c "
SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;
"

# 2. 如果延迟持续增长
#    - 看主库写入压力
#    - 看网络（主从之间）
#    - 必要时 rebuild replica
```

### D. 数据损坏（罕见但严重）

**症状**: 查询报 `invalid page header` / `data corruption`

**修复**: ⚠️ 立即联系 DBA + 启动 P0 事故

```bash
# 1. 立即停止写入（避免进一步损坏）
ld flag set user-service.readonly-mode --enabled true

# 2. DBA 评估损坏范围
kubectl exec -it postgres-primary-0 -n user-service-prod -- psql -U admin -d users -c "
SELECT * FROM pg_stat_database WHERE datname = 'users';
"

# 3. 从备份恢复（最近的 PITR point）
# 见下方"灾难恢复"章节
```

---

## 🚑 主库切换（Promote Replica）

如果主库**确认无法恢复**，需要把从库升级为主库：

```bash
# ⚠️ 必须 DBA 执行，全公司通知

# 1. 在从库上 promote
kubectl exec -it postgres-replica-0 -n user-service-prod -- \
  pg_ctl promote -D /var/lib/postgresql/data

# 2. 等 promote 完成（< 30s）
kubectl exec -it postgres-replica-0 -n user-service-prod -- \
  pg_isready

# 3. 改 Service 指向新主库
kubectl patch service postgres-primary -n user-service-prod \
  -p '{"spec":{"selector":{"statefulset.kubernetes.io/pod-name":"postgres-replica-0"}}}'

# 4. 验证应用连接
kubectl logs -n user-service-prod -l app=user-service --tail=50 | grep "db connection"

# 5. 把原主库重建为新从库
kubectl exec -it postgres-primary-0 -n user-service-prod -- \
  rm -rf /var/lib/postgresql/data/*  # 清空数据
# StatefulSet 会重启作为 replica
```

---

## 💾 灾难恢复（备份还原）

### 备份策略（详见 deployment.md）

| 数据 | 频率 | 保留 |
|------|------|------|
| 全量 | 每日 03:00 | 30 天 |
| 增量 (WAL) | 每 15 分钟 | 7 天 |

### RTO / RPO

| 场景 | RTO | RPO |
|------|-----|-----|
| 单实例崩溃 | < 5 分钟 | 0 |
| AZ 故障 | < 5 分钟 | 0 |
| 区域故障 | < 30 分钟 | < 15 分钟 |
| **数据损坏** | < 2 小时 | < 15 分钟 |

### 从备份恢复

```bash
# 1. 找到最近的备份
aws s3 ls s3://company-backups/user-service/postgres/

# 2. 启动临时恢复实例
kubectl apply -f k8s/postgres-recovery.yaml

# 3. 下载 + restore
kubectl exec -it postgres-recovery-0 -n user-service-prod -- \
  /scripts/restore-from-s3.sh s3://company-backups/user-service/postgres/2026-06-21/dump.sql.gz

# 4. 验证数据完整性
# - 行数对比
# - 抽样查询
# - 应用端冒烟

# 5. 切换流量
# 同"主库切换"步骤
```

---

## 📊 恢复验证

```bash
# 1. 数据库连接
kubectl exec -it postgres-primary-0 -n user-service-prod -- psql -U admin -d users -c "SELECT 1;"

# 2. 应用连接
curl -s https://user.company.com/readyz
# 期望: database: ok

# 3. 业务冒烟
./scripts/smoke-test.sh https://user.company.com

# 4. 数据一致性
kubectl exec -it postgres-primary-0 -n user-service-prod -- psql -U admin -d users -c "
SELECT count(*) FROM users WHERE deleted_at IS NULL;
"
# 对比 Grafana 历史数据
```

---

## ⚠️ 严禁操作

| ❌ 永远不要 | 原因 |
|-----------|------|
| 在主库手动 DROP / TRUNCATE | 数据不可恢复 |
| 不经 DBA 擅自 promote replica | 可能脑裂 |
| 跳过备份恢复流程 | 可能错失最佳恢复点 |
| 隐瞒数据损坏 | 越早处理损失越小 |

---

## 🔗 相关

- [部署架构 - 备份](../architecture/deployment.md#6-灾备-dr)
- [数据流](../architecture/data-flow.md)
- [ER 图](../architecture/diagrams/er-diagram.md)
- [事故 Postmortem 模板](../project/postmortems/template.md)
