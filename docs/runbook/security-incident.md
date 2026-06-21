# RB-008: 安全事件

> **等级**: 🔴 P0（永远）  
> **响应时间**: 立即  
> **联系**: Security Team @security, PagerDuty escalation

---

## 🚨 立即行动（5 分钟内）

### 1. 启动 P0 事故

```bash
/incident new P0 "Security incident"
# 自动通知: EM + Security + Legal + CTO
```

### 2. 启动应急小组

```
IC: Security Lead
Comms: EM + Legal
Tech: on-call 工程师
Scribe: 任何人（必须有）
```

### 3. 隔离（containment）

```bash
# 1. 立即封锁可疑 IP
iptables -A INPUT -s <malicious-ip> -j DROP

# 2. 撤销可疑 session
redis-cli --scan --pattern "session:*:user_id=<user_id>" | xargs redis-cli del

# 3. 撤销可疑 token
redis-cli --scan --pattern "jwt:blacklist:*" | xargs redis-cli set <jti> 1 EX 86400

# 4. 临时禁用可疑账户
psql -c "UPDATE users SET status='disabled' WHERE id IN (<suspicious_ids>);"
```

---

## 🔍 取证（不能破坏证据！）

```bash
# 1. 立即备份日志
kubectl logs -n user-service-prod -l app=user-service --since=2h > /tmp/incident-logs-$(date +%s).txt

# 2. 备份审计日志（Kafka）
kafka-console-consumer.sh --bootstrap-server kafka:9092 \
  --topic audit.events --from-beginning --max-messages 10000 > /tmp/audit-$(date +%s).json

# 3. 备份 DB 相关表
pg_dump -t user_audit_log -t users --where="..." > /tmp/db-$(date +%s).sql

# 4. 锁定相关时间段的配置变更记录
git log --since="2 hours ago" > /tmp/code-changes-$(date +%s).txt
```

---

## 📋 评估范围

| 问题 | 检查 |
|------|------|
| 哪些数据被访问？ | 审计日志 + DB log |
| 哪些账户被影响？ | 异常登录分析 |
| 哪些权限被滥用？ | 权限审计 |
| 数据是否被导出？ | 网络流量分析 |
| 是否有横向移动？ | 关联用户行为 |

---

## 🛠 修复

### 凭据泄露

```bash
# 1. 重置所有受影响用户密码
# 2. 强制 SSO re-auth
# 3. 撤销所有 JWT (jti 进黑名单)
# 4. 通知用户（不要邮件泄露更多细节）
```

### SQL 注入

```bash
# 1. 紧急修复代码
# 2. 看 DB log 找到攻击 payload
# 3. 检查所有受影响记录
# 4. 更新 WAF 规则
```

### 内部威胁（员工滥用）

```bash
# 1. 立即撤销访问
# 2. 联系 HR + Legal
# 3. 保留所有证据（不能删除）
# 4. 启动调查（可能报警）
```

---

## 📞 外部通知

### 何时通知？

| 情况 | 必须通知 |
|------|----------|
| 用户 PII 泄漏 | ✅ 用户 + 监管 |
| 内部数据 | ⚠️ 仅高管 + Legal |
| 服务被攻击但未失陷 | ⚠️ 仅 Security + EM |

### GDPR / CCPA 报告时限

- **72 小时内**通知监管机构
- **立即**通知受影响用户（如有 PII）

---

## 🔒 修复后

1. **Postmortem**: 48 小时内（用专用模板）
2. **行动项**: Owner + Due（特别是修复 + 加固）
3. **回归测试**: 加 E2E 安全测试
4. **培训**: 团队分享（脱敏后）

---

## ⚠️ 绝对禁止

| ❌ 不要 | 原因 |
|---------|------|
| 私下修复不报告 | 错过早期响应 |
| 删除日志 | 销毁证据 |
| 通知不全 | 法律风险 |
| 公开细节（社交媒体等）| 攻击者可利用 |

---

## 🔗 相关

- [Postmortem 模板](../project/postmortems/template.md)
- [业务规则 - 安全红线](../requirements/business-rules.md)
- [架构 - 安全](../architecture/overview.md#7-安全架构)
