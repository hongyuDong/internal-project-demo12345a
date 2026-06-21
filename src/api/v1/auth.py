"""
Auth API 路由

参考 docs/api/openapi.yaml 的 /v1/auth/* 端点
"""

from fastapi import APIRouter, Depends

from src.core.security import get_current_user

router = APIRouter(tags=["Auth"])


@router.get("/me")
async def get_me(current_user: dict = Depends(get_current_user)):
    """
    获取当前用户信息。

    对应 OpenAPI: GET /v1/auth/me
    """
    return current_user


@router.post("/logout", status_code=204)
async def logout(current_user: dict = Depends(get_current_user)):
    """
    登出（撤销当前 token）。

    对应 OpenAPI: POST /v1/auth/logout

    实际实现：把当前 JWT 的 jti 加入 Redis 黑名单。
    """
    # await redis.setex(f"jwt:blacklist:{jti}", 86400, "1")
    return None
