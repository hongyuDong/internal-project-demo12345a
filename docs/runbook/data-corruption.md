# RB-007: 数据损坏 / 不一致

> **等级**: 🔴 P0  
> **典型触发**: DB 报错 `invalid page header` / 业务反馈数据错乱

---

## 🚨 立即行动

### 1. 隔离写入

```bash
# 切只读模式（防损坏扩散）
ld flag set user-service.readonly-mode --enabled true
```

### 2. 评估范围

```bash
# 1. 立即全表扫描
psql -d users -c "
SELECT relname, n_live_tup, n_dead_tup, n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables
ORDER BY n_tup_upd DESC;
"

# 2. 检查索引健康
psql -d users -c "
SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0;
"

# 3. 数据抽样校验
# 写脚本对比"应该不变"的数据
```

---

## 🛠 修复

### A. 索引损坏

```bash
# 重建索引（CONCURRENTLY 不锁表）
REINDEX INDEX CONCURRENTLY ix_users_email;

# 验证
ANALYZE users;
```

### B. 行损坏

```bash
# 找到具体坏行
VACUUM FULL ANALYZE users;
# 看哪些行报错

# 隔离坏行
SELECT id FROM users WHERE id IN (...);

# 从备份恢复特定行
# （需要 DBA 评估）
```

### C. 整体表损坏

```bash
# 1. 从最近的备份恢复
# 2. 用备份 + WAL 做 PITR（Point-in-Time Recovery）
# 3. 业务数据验证

# 详见 [db-primary-failure.md](db-primary-failure.md#灾难恢复备份还原)
```

---

## 📊 恢复验证

- [ ] 抽样业务数据 vs 备份
- [ ] 关键 API 冒烟测试
- [ ] 关闭只读模式
- [ ] 监控 1 小时无异常

---

## 🔗 相关

- [数据库故障 Runbook](db-primary-failure.md)
- [Postmortem 模板](../project/postmortems/template.md)
