"""
安全模块：JWT 验证 + 用户认证

参考 ADR-0003 (JWT vs Session)。
"""

import time
from typing import Annotated
from uuid import UUID

import jwt
import structlog
from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from src.core.config import settings
from src.core.cache import get_cached_user

logger = structlog.get_logger()
security = HTTPBearer()


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
) -> dict:
    """
    验证 JWT 并返回当前用户。

    完整实现见 ADR-0003 + docs/architecture/sequence-login.md

    Returns:
        用户信息 dict（id, email, role, permissions）
    """
    token = credentials.credentials

    # 1. 验证 JWT 签名
    try:
        payload = jwt.decode(
            token,
            await get_jwks_public_key(),
            algorithms=["RS256"],
            audience=settings.jwt_audience,
            issuer=settings.sso_issuer,
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="token_expired",
        )
    except jwt.InvalidTokenError as e:
        logger.warning("invalid_jwt", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid_token",
        )

    # 2. 检查黑名单
    jti = payload.get("jti")
    if jti and await is_token_revoked(jti):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="token_revoked",
        )

    # 3. 查用户（优先 Redis 缓存）
    user_id = payload.get("sub")
    user = await get_cached_user(user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="user_not_found",
        )

    if user["status"] != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"user_{user['status']}",
        )

    return user


async def get_jwks_public_key() -> str:
    """从 SSO 获取 JWKS 公钥（带缓存）"""
    # 实际实现：HTTP 请求 SSO 的 JWKS endpoint，缓存 1 小时
    # from jwks_client import PyJWKClient
    # jwks_client = PyJWKClient(settings.sso_jwks_url, cache_keys=True)
    # signing_key = jwks_client.get_signing_key_from_jwt(token).key
    # return signing_key
    return "PLACEHOLDER_PUBLIC_KEY"


async def is_token_revoked(jti: str) -> bool:
    """检查 token 是否在 Redis 黑名单"""
    # 实际：return await redis.exists(f"jwt:blacklist:{jti}")
    return False


def require_role(role: str):
    """依赖注入：要求特定角色"""
    async def _check(user: dict = Depends(get_current_user)) -> dict:
        if role not in user.get("roles", []):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"requires_role_{role}",
            )
        return user
    return _check


def require_permission(permission: str):
    """依赖注入：要求特定权限"""
    async def _check(user: dict = Depends(get_current_user)) -> dict:
        if permission not in user.get("permissions", []):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"requires_permission_{permission}",
            )
        return user
    return _check
