"""
Users API 路由（骨架）

完整实现参见 docs/api/openapi.yaml 和 skills/create-new-endpoint/SKILL.md
"""

from uuid import UUID
from fastapi import APIRouter, Depends, Header, HTTPException, Query, status

from src.core.security import get_current_user
from src.core.cache import invalidate_user_cache

router = APIRouter(tags=["Users"])


@router.get("")
async def list_users(
    cursor: str | None = Query(None),
    limit: int = Query(50, ge=1, le=200),
    department_id: UUID | None = Query(None),
    current_user: dict = Depends(get_current_user),
):
    """
    列出用户（cursor-based 分页）。

    对应 OpenAPI: GET /v1/users
    """
    # 实际实现：
    # 1. 检查权限 users:read
    # 2. 查 DB（带 cursor 分页）
    # 3. 写缓存（如适用）
    # 4. 写审计
    raise NotImplementedError("TODO: 实现 list_users")


@router.post("", status_code=201)
async def create_user(
    payload: dict,  # TODO: UserCreate schema
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    current_user: dict = Depends(get_current_user),
):
    """
    创建用户。

    对应 OpenAPI: POST /v1/users
    """
    # 1. 幂等检查
    # 2. 校验 BR-001（邮箱唯一）、BR-002（工号唯一）、BR-006（manager 同部门）
    # 3. INSERT
    # 4. 分配默认 employee 角色（BR-007）
    # 5. 写审计
    # 6. 发 Kafka user.created 事件
    raise NotImplementedError("TODO: 实现 create_user")


@router.get("/{user_id}")
async def get_user(
    user_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """
    获取用户详情。

    对应 OpenAPI: GET /v1/users/{id}
    """
    raise NotImplementedError("TODO: 实现 get_user")


@router.patch("/{user_id}")
async def update_user(
    user_id: UUID,
    payload: dict,  # TODO: UserUpdate schema
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    current_user: dict = Depends(get_current_user),
):
    """
    部分更新用户。

    对应 OpenAPI: PATCH /v1/users/{id}
    """
    # 改完后失效缓存
    await invalidate_user_cache(str(user_id))
    raise NotImplementedError("TODO: 实现 update_user")


@router.delete("/{user_id}", status_code=204)
async def delete_user(
    user_id: UUID,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    current_user: dict = Depends(get_current_user),
):
    """
    软删用户（BR-012）。

    对应 OpenAPI: DELETE /v1/users/{id}
    """
    raise NotImplementedError("TODO: 实现 delete_user")
