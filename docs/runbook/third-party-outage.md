# RB-010: 第三方依赖故障

> **等级**: 🟡 P1（核心依赖 → 🔴 P0）  
> **典型触发**: SSO / Vault / Datadog / 第三方 API 不可用

---

## 📊 第三方依赖清单

| 服务 | 用途 | 等级 | 备份方案 |
|------|------|------|----------|
| SSO | 用户认证 | 🔴 核心 | 降级：临时接受过期 JWT |
| Vault | 密钥管理 | 🔴 核心 | 缓存本地 fallback |
| Datadog | APM/日志 | 🟢 非核心 | 降级到 stdout 日志 |
| PagerDuty | 告警 | 🟡 重要 | Slack 通知 fallback |
| LaunchDarkly | Feature flags | 🟡 重要 | 默认值 fallback |

---

## 🛠 各依赖详细

### A. SSO 故障

**症状**: JWT 验签失败 / JWKS 不可达

**修复**: 见 [login-failure.md](login-failure.md)

### B. Vault 故障

**症状**: 启动失败 / secret 读取失败

**修复**:
```bash
# 1. 用本地缓存（K8s 会同步到本地 secret）
#    External Secrets Operator 已经缓存

# 2. 检查 vault 状态
kubectl exec -it vault-0 -n user-service-prod -- vault status

# 3. 重启 vault
kubectl rollout restart statefulset/vault -n user-service-prod

# 4. 紧急：手动重新同步 secret
kubectl exec -it <pod> -n user-service-prod -- \
  curl -X POST http://localhost:8000/admin/resync-secrets
```

### C. Datadog 故障

**症状**: 监控数据缺失 / 日志不显示

**修复**: 不紧急，等 Datadog 团队恢复

### D. 第三方 API 故障（如 HR 系统）

**症状**: 入职 / 离职失败

**修复**:
```bash
# 1. 切到 Outbox 重试（已有）
# 2. 看 Outbox 表积压
psql -c "SELECT count(*), status FROM outbox GROUP BY status;"

# 3. 第三方恢复后自动重试
# 4. 必要时手动触发
./scripts/replay-outbox.sh
```

---

## 📊 第三方 SLA 监控

| 服务 | 公司 SLA | 我们容忍 | 告警阈值 |
|------|----------|----------|----------|
| SSO | 99.95% | 99.9% | < 99.5% |
| Vault | 99.99% | 99.95% | < 99.9% |
| Datadog | 99.9% | 99.5% | < 99% |

---

## 🛡 通用建议

1. **永远有 fallback 方案**：缓存、默认值、stale data
2. **超时设置必须保守**：3s 连接超时，5s 读超时
3. **熔断器**：连续失败 N 次后自动跳过
4. **监控第三方健康**：主动探测（每 30s）
