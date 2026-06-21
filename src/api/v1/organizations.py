"""
Organizations API 路由（骨架）

完整实现参考 docs/api/openapi.yaml
"""

from uuid import UUID
from fastapi import APIRouter, Depends, Query

from src.core.security import get_current_user

router = APIRouter(tags=["Organizations"])


@router.get("")
async def list_organizations(
    parent_id: UUID | None = Query(None),
    tree: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
    """
    列出组织（支持树形结构）。

    对应 OpenAPI: GET /v1/organizations
    """
    raise NotImplementedError("TODO: 实现 list_organizations")


@router.get("/{org_id}")
async def get_organization(
    org_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """
    获取组织详情（含子树）。

    对应 OpenAPI: GET /v1/organizations/{id}
    """
    raise NotImplementedError("TODO: 实现 get_organization")
