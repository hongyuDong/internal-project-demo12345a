# ADR-0003: 认证机制选型 - JWT vs Server-side Session

**状态**: ✅ Accepted  
**日期**: 2025-09-15  
**决策人**: @arch-lead, @security-lead

## 背景

公司 SSO 已颁发 JWT。本服务需要决定：
- 直接接受 SSO 的 JWT（无状态）
- 还是换成自己的 session（有状态）

## 决策

**接受 SSO 的 JWT（RS256 签名），不维护 session。**

只在 Redis 存必要的状态（黑名单 / 限流计数器），不存完整 session。

## 备选方案

### 选项 A：JWT 无状态（已选）
- ✅ 无状态，易扩展
- ✅ 跨服务共享（同一 JWT）
- ✅ 减少 DB 查询
- ❌ 撤销困难（需要黑名单）

### 选项 B：Server-side Session
- ✅ 立即撤销（删 session）
- ❌ 状态存储成本（Redis）
- ❌ 跨服务共享难

### 选项 C：Hybrid（session + JWT claims）
- ✅ 灵活
- ❌ 复杂度高

## 实现

### JWT 验证

```python
# 伪代码
def verify_jwt(token: str) -> User:
    # 1. 用 SSO 公钥验签（缓存公钥）
    payload = jwt.decode(token, public_key, algorithms=["RS256"])
    
    # 2. 检查 iss / aud / exp
    if payload['iss'] != 'sso.company.com':
        raise InvalidToken
    
    # 3. 检查 jti 黑名单（Redis）
    if await redis.exists(f"jwt:blacklist:{payload['jti']}"):
        raise RevokedToken
    
    # 4. 查用户基本信息（缓存）
    user = await cache_get_user(payload['sub'])
    return user
```

### 撤销机制

JWT 一旦签发不能"收回"，只能：
1. **短过期**（access token 1h，refresh 30d）
2. **黑名单**（撤销后 jti 进 Redis 24h）
3. **版本号**（user 表存 `token_version`，签发时绑定，旧版本失效）

我们用 1 + 2 + 3。

### Refresh Token

```yaml
access_token:
  expires_in: 3600  # 1 hour
  storage: HttpOnly cookie + SameSite=Strict
  
refresh_token:
  expires_in: 2592000  # 30 days
  storage: HttpOnly cookie (separate path /auth)
  rotation: 每次 refresh 都换新的
```

## 影响

### 正面
- ✅ 性能好（无 DB session 验证）
- ✅ 跨服务容易
- ✅ 简化部署（无状态）

### 负面
- 撤销延迟最长 1 小时（access 过期）
- 需要维护黑名单机制

## 后果

- ✅ **必须**: access token 1 小时过期
- ✅ **必须**: 黑名单检查每次请求
- ✅ **必须**: refresh token rotation
- ✅ **必须**: HttpOnly + Secure + SameSite=Strict cookie
- ❌ **禁止**: 把 JWT 存 localStorage（XSS 风险）
