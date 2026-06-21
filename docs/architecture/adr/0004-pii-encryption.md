# ADR-0004: PII 字段加密策略

**状态**: ✅ Accepted  
**日期**: 2025-12-01  
**决策人**: @arch-lead, @security-lead, @compliance  
**关联业务规则**: BR-011

## 背景

`internal-user-service` 存储大量员工 PII（个人可识别信息）：

| 字段 | 敏感度 | 合规要求 |
|------|--------|----------|
| `email` | 中 | GDPR / CCPA |
| `phone` | 高 | GDPR / CCPA / 等保 |
| `id_card` | 🔴 极高 | 等保三级 |
| `address` | 高 | GDPR / CCPA |
| `photo` | 高 | GDPR |

需要选择加密策略，平衡：
- 安全性（密钥泄漏风险）
- 可用性（可搜索 / 可分析）
- 性能（加密 / 解密开销）
- 运维（密钥轮换）

## 决策

采用**列级加密（Column-Level Encryption）** + **应用层密钥管理**：

```python
# 数据模型（伪代码）
class User(Base):
    email = Column(String(255), unique=True)  # 明文（用于登录查询）
    phone_enc = Column(LargeBinary)          # 加密
    id_card_enc = Column(LargeBinary)        # 加密
    address_enc = Column(LargeBinary)        # 加密
```

**加密算法**：AES-256-GCM（带认证的加密）

**密钥管理**：HashiCorp Vault 统一管理

**密钥轮换**：每 90 天自动轮换

## 备选方案

### 方案 A：列级加密（已选）

- ✅ 字段级粒度
- ✅ 不影响非 PII 字段性能
- ✅ 密钥轮换影响范围可控
- ✅ DB 备份泄漏风险低
- ❌ 不能在 DB 层做 LIKE 查询（phone 模糊搜索）
- ❌ 应用层稍复杂

### 方案 B：行级 / 表级加密（TDE）

- ✅ 实现简单
- ✅ 性能好（透明加密）
- ❌ 太粗粒度（泄漏一份密钥 = 全部泄漏）
- ❌ 不符合最小权限原则

### 方案 C：全盘加密

- ✅ 实现最简单
- ❌ 只防物理盗窃，不防应用层泄漏
- ❌ 数据库管理员能直接看明文

### 方案 D：哈希（不可逆）

- ✅ 适合密码
- ❌ PII 必须可还原（用户查看 / 修改）
- ❌ 不适用

## 实现细节

### 密钥层次

```
┌─────────────────────────────────────┐
│ Master Key (Vault)                  │ ← 主密钥，只在 Vault
└──────────┬──────────────────────────┘
           │ 派生（Key Derivation）
           ▼
┌─────────────────────────────────────┐
│ Data Encryption Key (DEK)           │ ← 每 90 天轮换
│   - 用户密钥                         │
│   - 部门密钥                         │
│   - 审计密钥                         │
└──────────┬──────────────────────────┘
           │ 加密
           ▼
┌─────────────────────────────────────┐
│ Encrypted Data (DB)                  │ ← AES-256-GCM
│   - phone_enc                        │
│   - id_card_enc                      │
│   - address_enc                      │
└─────────────────────────────────────┘
```

### 加密 / 解密（Python 伪代码）

```python
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os
from src.core.vault import get_dek  # 从 Vault 拉 DEK


def encrypt_pii(plaintext: str, key_id: str = "user-dek") -> bytes:
    """加密 PII 字段"""
    dek = get_dek(key_id)  # 从 Vault 拿 DEK（带缓存）
    nonce = os.urandom(12)
    aesgcm = AESGCM(dek)
    ciphertext = aesgcm.encrypt(nonce, plaintext.encode(), None)
    return nonce + ciphertext  # nonce 前 12 字节


def decrypt_pii(ciphertext: bytes, key_id: str = "user-dek") -> str:
    """解密 PII 字段"""
    dek = get_dek(key_id)
    nonce = ciphertext[:12]
    ciphertext = ciphertext[12:]
    aesgcm = AESGCM(dek)
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    return plaintext.decode()
```

### 密钥轮换

```python
# 90 天自动轮换（cron job）
def rotate_dek():
    new_dek = generate_random_key()  # 256-bit
    
    # 1. 把新 DEK 写入 Vault
    vault.put("user-dek", new_dek)
    
    # 2. 重新加密存量数据（异步 job）
    for user in User.query.all():
        if user.phone_enc:
            plaintext = decrypt_pii(user.phone_enc, old_dek_id)
            user.phone_enc = encrypt_pii(plaintext, new_dek_id)
    
    # 3. 删除旧 DEK
    vault.delete("user-dek-2025-Q4")
```

### 性能影响

| 操作 | 明文 | 加密 | 差异 |
|------|------|------|------|
| INSERT | 5ms | 7ms | +2ms |
| SELECT | 3ms | 5ms | +2ms |
| 批量插入 1000 行 | 500ms | 700ms | +200ms |
| 解密显示 | - | 1ms | 用户无感 |

**结论**：性能影响可接受。

## 影响

### 正面
- ✅ DB 备份泄漏 = 加密的 PII（攻击者拿 Vault 才能解）
- ✅ DB 管理员不能直接看 PII
- ✅ 满足等保三级 + GDPR
- ✅ 密钥泄漏影响范围可控

### 负面
- ❌ 不能在 DB 做 LIKE 查询 phone（必须应用层解密 + 模糊匹配）
- ❌ 备份恢复需要 Vault 在线
- ❌ 密钥轮换期间性能有抖动

### 风险
- 🟡 Vault 不可用 → 无法解密（**需 cache DEK**）
- 🟡 DEK 泄漏 → 历史 PII 暴露（**需审计 + 自动轮换**）
- 🟡 性能抖动 → 批量更新可能慢（**异步处理**）

## 后果

✅ **必须**：
- 所有 PII 字段加密后才能入库
- 密钥从 Vault 读取，**永不**进代码 / env
- 应用层做权限检查（谁能解）
- 每次解密写审计日志

❌ **禁止**：
- 在日志中打印明文 PII
- 用 `phone LIKE '%1234%'` 类 SQL 查询
- 把 DEK 提交到 git
- 把 DEK 写到 `.env` 文件

⚠️ **注意**：
- 加密字段查询必须用 deterministic encryption（**搜索场景**）或解密后过滤
- 密钥轮换期间可能有几秒的解密失败（**降级到缓存**）

## 验证

- ✅ 渗透测试：DB 备份无法解出 PII
- ✅ 合规审计：等保三级 + GDPR 通过
- ✅ 性能测试：批量加密 < 1s / 1000 行
- ✅ 灾备演练：Vault 不可用时 cache 兜底成功
