# Security Policy

> 如何报告 Claude Code 模板中的安全漏洞

---

## 支持的版本

| 版本 | 支持状态 |
|------|---------|
| 最新 v1.0.x | ✅ 积极维护 |
| v1.0.0 | ⚠️ 仅关键安全修复 |
| < v1.0 | ❌ 不支持 |

## 报告漏洞

**请不要** 在 GitHub Issues 公开报告安全漏洞。

### 私下报告方式

📧 **Email**: security@company.com  
🔐 **PGP**: [key on https://company.com/pgp-key](https://company.com/pgp-key)  
💬 **Slack**: `#security-team`（紧急情况）

### 报告内容

请包含：

1. **漏洞类型**（密钥泄漏 / 权限提升 / RCE / ...）
2. **影响范围**（哪个文件 / 哪个 hook / 哪个 settings）
3. **复现步骤**
4. **潜在影响**
5. **修复建议**（可选）

### 示例报告

```
标题: [CRITICAL] secret-scanner 漏报 AWS key

类型: 密钥泄漏
严重度: 🔴 Critical
文件: .claude/hooks/secret-scanner.sh
版本: v1.0.2

描述:
当前 secret-scanner 用 grep -E 'AKIA[0-9A-Z]{16}' 检测 AWS key。
但新的 AWS session token 用 'ASIA[0-9A-Z]{16}'，未被覆盖。

复现:
1. 创建含 ASIAIOSFODNN7EXAMPLE 的文件
2. 让 Claude 写入
3. 实际: 不阻断
4. 期望: 阻断

影响: 攻击者可绕过 secret-scanner

建议: 同时匹配 AKIA 和 ASIA 模式
```

## 响应时间

| 严重度 | 首次响应 | 修复 SLA |
|--------|----------|---------|
| 🔴 Critical | 24h | 7 天 |
| 🟡 High | 3 天 | 30 天 |
| 🟢 Medium | 7 天 | 90 天 |
| ⚪ Low | 14 天 | 下个 release |

## 协调披露

我们承诺：

- ✅ 收到报告 24h 内确认
- ✅ 调查期间保持联系
- ✅ 修复后公开致谢（如果你同意）
- ❌ 修复前不公开细节
- ❌ 不会因为善意报告而起诉你

## 已知安全机制

本模板已有的安全机制：

- ✅ `.claude/hooks/secret-scanner.{sh,ps1}` — 检测 13+ 种密钥 pattern
- ✅ `.claude/hooks/bash-policy.{sh,ps1}` — 拦截危险命令
- ✅ `.claude/hooks/audit-log.{sh,ps1}` — 全链路审计
- ✅ `settings.json` — 45 allow / 46 deny / 26 ask 三层权限

如发现这些机制有缺陷，请报告。

## 安全公告

安全公告发布在：
- GitHub Security Advisories
- Slack `#security-announcements`
- 邮件列表 `security-announce@company.com`
