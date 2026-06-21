"""
Redis 缓存层

参考 ADR-0005 (Permission Cache Strategy)。
"""

import json
from typing import Any, Optional
from uuid import UUID

import redis.asyncio as redis
import structlog

from src.core.config import settings

logger = structlog.get_logger()

# Redis 客户端单例
_redis_client: Optional[redis.Redis] = None


def get_redis() -> redis.Redis:
    """获取 Redis 客户端"""
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
        )
    return _redis_client


async def get_cached_user(user_id: str) -> Optional[dict]:
    """
    从 Redis 缓存获取用户。

    缓存策略：
    - Key: user:{user_id}
    - TTL: 5 分钟（settings.redis_cache_ttl）
    - 失效：写后失效
    """
    if settings.cache_bypass_enabled:
        return None

    try:
        cached = await get_redis().get(f"user:{user_id}")
        if cached:
            return json.loads(cached)
    except Exception as e:
        logger.warning("cache_get_failed", user_id=user_id, error=str(e))
        # 降级：不阻断请求，让上游查 DB

    return None


async def set_cached_user(user_id: str, user_data: dict) -> None:
    """写入用户缓存"""
    if settings.cache_bypass_enabled:
        return

    try:
        await get_redis().setex(
            f"user:{user_id}",
            settings.redis_cache_ttl,
            json.dumps(user_data, default=str),
        )
    except Exception as e:
        logger.warning("cache_set_failed", user_id=user_id, error=str(e))


async def invalidate_user_cache(user_id: str) -> None:
    """
    失效用户缓存。

    在以下场景调用：
    - 用户更新
    - 权限变更
    - 用户被停用
    """
    try:
        await get_redis().delete(
            f"user:{user_id}",
            f"user:{user_id}:permissions",
        )
    except Exception as e:
        logger.warning("cache_invalidate_failed", user_id=user_id, error=str(e))


async def get_cached_permissions(user_id: str) -> Optional[set[str]]:
    """获取用户有效权限（含继承）"""
    if settings.cache_bypass_enabled:
        return None

    try:
        cached = await get_redis().get(f"user:{user_id}:permissions")
        if cached:
            return set(json.loads(cached))
    except Exception as e:
        logger.warning("cache_perms_failed", user_id=user_id, error=str(e))

    return None


async def set_cached_permissions(user_id: str, permissions: set[str]) -> None:
    """写入权限缓存"""
    if settings.cache_bypass_enabled:
        return

    try:
        await get_redis().setex(
            f"user:{user_id}:permissions",
            settings.redis_cache_ttl,
            json.dumps(list(permissions)),
        )
    except Exception as e:
        logger.warning("cache_perms_set_failed", user_id=user_id, error=str(e))
