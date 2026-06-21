---
name: create-new-endpoint
description: Create a new REST API endpoint following company standards. Use when user says "add endpoint for X" or "create API for Y".
---

# Create New Endpoint

按公司规范新建 REST API 端点。完整覆盖：路由 → schema → service → repository → 测试 → 文档。

## 工作流

### Step 1: 确认需求

跟用户确认：
- [ ] 端点路径和方法（GET / POST / PUT / PATCH / DELETE）
- [ ] 请求参数（path / query / body / header）
- [ ] 响应 schema
- [ ] 错误场景
- [ ] 权限要求（哪些角色可访问）
- [ ] 是否需要审计
- [ ] 是否发 Kafka 事件

### Step 2: 调研现有代码

```bash
# 找类似端点
grep -rn "router\.\(get\|post\|put\|delete\)" src/api/v1/ | head -20

# 读现有 router 文件结构
ls src/api/v1/
cat src/api/v1/users.py | head -50

# 找类似 service
ls src/services/
cat src/services/user_service.py | head -50

# 找类似 schema
ls src/schemas/
cat src/schemas/user.py | head -50
```

### Step 3: 创建 Pydantic Schema

```python
# src/schemas/{resource}.py
from datetime import datetime
from pydantic import BaseModel, Field, EmailStr
from uuid import UUID


class {Resource}Create(BaseModel):
    """创建{Resource}的请求 schema"""
    name: str = Field(..., min_length=1, max_length=100, description="名称")
    email: EmailStr = Field(..., description="邮箱地址")
    # 添加其他字段
    
    class Config:
        json_schema_extra = {
            "example": {
                "name": "张三",
                "email": "zhangsan@company.com"
            }
        }


class {Resource}Update(BaseModel):
    """更新{Resource}的请求 schema"""
    name: str | None = Field(None, min_length=1, max_length=100)


class {Resource}Response(BaseModel):
    """响应 schema"""
    id: UUID
    name: str
    email: EmailStr
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class {Resource}ListResponse(BaseModel):
    """列表响应"""
    data: list[{Resource}Response]
    next_cursor: str | None
    has_more: bool
```

### Step 4: 创建 SQLAlchemy Model（如果还没有）

```python
# src/models/{resource}.py
from sqlalchemy import String, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from uuid import UUID as PyUUID, uuid4
from datetime import datetime

from src.core.database import Base


class {Resource}(Base):
    __tablename__ = "{resources}"
    
    id: Mapped[PyUUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
```

### Step 5: 创建 Alembic 迁移

```bash
# 自动生成
alembic revision --autogenerate -m "add_{resources}_table"

# ⚠️ 必须人工 review 自动生成的迁移
# 1. 检查 upgrade / downgrade 完整
# 2. 加索引用 CONCURRENTLY
# 3. 加 NOT NULL 列必须分步
```

### Step 6: 创建 Repository

```python
# src/repositories/{resource}_repository.py
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.{resource} import {Resource}


class {Resource}Repository:
    def __init__(self, session: AsyncSession):
        self.session = session
    
    async def get(self, id: UUID) -> {Resource} | None:
        result = await self.session.execute(
            select({Resource}).where(
                {Resource}.id == id,
                {Resource}.deleted_at.is_(None)
            )
        )
        return result.scalar_one_or_none()
    
    async def list(self, cursor: str | None = None, limit: int = 50) -> tuple[list[{Resource}], str | None]:
        # Cursor-based pagination
        stmt = select({Resource}).where({Resource}.deleted_at.is_(None)).limit(limit + 1)
        if cursor:
            # decode cursor and apply
            pass
        result = await self.session.execute(stmt)
        items = result.scalars().all()
        has_more = len(items) > limit
        next_cursor = encode_cursor(items[-1].id) if has_more else None
        return items[:limit], next_cursor
    
    async def create(self, data: dict) -> {Resource}:
        item = {Resource}(**data)
        self.session.add(item)
        await self.session.commit()
        await self.session.refresh(item)
        return item
    
    async def update(self, id: UUID, data: dict) -> {Resource} | None:
        item = await self.get(id)
        if not item:
            return None
        for k, v in data.items():
            setattr(item, k, v)
        await self.session.commit()
        await self.session.refresh(item)
        return item
    
    async def soft_delete(self, id: UUID) -> bool:
        item = await self.get(id)
        if not item:
            return False
        item.deleted_at = datetime.utcnow()
        await self.session.commit()
        return True
```

### Step 7: 创建 Service

```python
# src/services/{resource}_service.py
from uuid import UUID
import structlog

from src.repositories.{resource}_repository import {Resource}Repository
from src.schemas.{resource} import {Resource}Create, {Resource}Update, {Resource}Response
from src.events.publisher import EventPublisher

logger = structlog.get_logger()


class {Resource}Service:
    def __init__(
        self,
        repo: {Resource}Repository,
        events: EventPublisher,
    ):
        self.repo = repo
        self.events = events
    
    async def get(self, id: UUID) -> {Resource}Response:
        item = await self.repo.get(id)
        if not item:
            raise {Resource}NotFoundError(id)
        return {Resource}Response.model_validate(item)
    
    async def list(self, cursor: str | None = None, limit: int = 50) -> {Resource}ListResponse:
        items, next_cursor = await self.repo.list(cursor, limit)
        return {Resource}ListResponse(
            data=[{Resource}Response.model_validate(i) for i in items],
            next_cursor=next_cursor,
            has_more=next_cursor is not None,
        )
    
    async def create(self, payload: {Resource}Create, actor_id: UUID) -> {Resource}Response:
        # 1. 业务校验
        existing = await self.repo.get_by_email(payload.email)
        if existing:
            raise {Resource}AlreadyExistsError(payload.email)
        
        # 2. 创建
        item = await self.repo.create(payload.model_dump())
        
        # 3. 发事件
        await self.events.publish(
            topic="{resource}.created",
            key=str(item.id),
            value={"id": str(item.id), "email": item.email},
        )
        
        # 4. 审计日志
        await logger.ainfo(
            "{resource}_created",
            resource_id=str(item.id),
            actor_id=str(actor_id),
        )
        
        return {Resource}Response.model_validate(item)
    
    # ... update / delete 类似
```

### Step 8: 创建 Router

```python
# src/api/v1/{resource}.py
from uuid import UUID
from fastapi import APIRouter, Depends, Header, Query
from typing import Annotated

from src.core.deps import get_db, get_current_user, require_admin
from src.models.user import User
from src.schemas.{resource} import (
    {Resource}Create,
    {Resource}Update,
    {Resource}Response,
    {Resource}ListResponse,
)
from src.services.{resource}_service import {Resource}Service


router = APIRouter(prefix="/{resources}", tags=["{resources}"])


@router.get(
    "",
    response_model={Resource}ListResponse,
    summary="List {resources}",
    description="Returns a paginated list of {resources} using cursor-based pagination.",
)
async def list_{resources}(
    cursor: str | None = Query(None, description="Pagination cursor"),
    limit: int = Query(50, ge=1, le=200),
    db = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> {Resource}ListResponse:
    service = {Resource}Service({Resource}Repository(db), EventPublisher())
    return await service.list(cursor=cursor, limit=limit)


@router.post(
    "",
    response_model={Resource}Response,
    status_code=201,
    summary="Create new {resource}",
    description="Creates a new {resource}. Requires admin role.",
    responses={
        409: {"description": "{Resource} already exists"},
        422: {"description": "Validation error"},
    },
)
async def create_{resource}(
    payload: {Resource}Create,
    idempotency_key: Annotated[str, Header(alias="Idempotency-Key")],
    db = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> {Resource}Response:
    service = {Resource}Service({Resource}Repository(db), EventPublisher())
    return await service.create(payload, actor_id=current_user.id)


@router.get(
    "/{id}",
    response_model={Resource}Response,
    summary="Get {resource} by ID",
    responses={404: {"description": "{Resource} not found"}},
)
async def get_{resource}(
    id: UUID,
    db = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> {Resource}Response:
    service = {Resource}Service({Resource}Repository(db), EventPublisher())
    return await service.get(id)


@router.patch(
    "/{id}",
    response_model={Resource}Response,
    summary="Update {resource}",
)
async def update_{resource}(
    id: UUID,
    payload: {Resource}Update,
    db = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> {Resource}Response:
    service = {Resource}Service({Resource}Repository(db), EventPublisher())
    return await service.update(id, payload, actor_id=current_user.id)


@router.delete(
    "/{id}",
    status_code=204,
    summary="Delete {resource}",
)
async def delete_{resource}(
    id: UUID,
    db = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> None:
    service = {Resource}Service({Resource}Repository(db), EventPublisher())
    await service.delete(id, actor_id=current_user.id)
```

### Step 9: 注册 Router

```python
# src/api/v1/__init__.py
from fastapi import APIRouter
from src.api.v1.{resource} import router as {resource}_router

api_router = APIRouter(prefix="/v1")
api_router.include_router({resource}_router)
```

### Step 10: 写测试

```python
# tests/integration/test_{resource}.py
import pytest
from uuid import uuid4

pytestmark = pytest.mark.asyncio


class TestCreate{Resource}:
    async def test_success(self, client, admin_token):
        response = await client.post(
            "/v1/{resources}",
            json={"name": "Test", "email": "test@company.com"},
            headers={"Authorization": f"Bearer {admin_token}", "Idempotency-Key": str(uuid4())},
        )
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "test@company.com"
    
    async def test_duplicate_email(self, client, admin_token, existing_{resource}):
        response = await client.post(
            "/v1/{resources}",
            json={"name": "Test", "email": existing_{resource}.email},
            headers={"Authorization": f"Bearer {admin_token}", "Idempotency-Key": str(uuid4())},
        )
        assert response.status_code == 409
    
    async def test_unauthorized(self, client):
        response = await client.post(
            "/v1/{resources}",
            json={"name": "Test", "email": "test@company.com"},
            headers={"Idempotency-Key": str(uuid4())},
        )
        assert response.status_code == 401
    
    async def test_forbidden_non_admin(self, client, employee_token):
        response = await client.post(
            "/v1/{resources}",
            json={"name": "Test", "email": "test@company.com"},
            headers={"Authorization": f"Bearer {employee_token}", "Idempotency-Key": str(uuid4())},
        )
        assert response.status_code == 403
    
    @pytest.mark.parametrize("email", ["", "invalid", "@x.com", "x@"])
    async def test_invalid_email(self, client, admin_token, email):
        response = await client.post(
            "/v1/{resources}",
            json={"name": "Test", "email": email},
            headers={"Authorization": f"Bearer {admin_token}", "Idempotency-Key": str(uuid4())},
        )
        assert response.status_code == 422
    
    async def test_idempotency(self, client, admin_token):
        key = str(uuid4())
        payload = {"name": "Test", "email": "test@company.com"}
        r1 = await client.post("/v1/{resources}", json=payload, headers={"Authorization": f"Bearer {admin_token}", "Idempotency-Key": key})
        r2 = await client.post("/v1/{resources}", json=payload, headers={"Authorization": f"Bearer {admin_token}", "Idempotency-Key": key})
        assert r1.json()["id"] == r2.json()["id"]
```

### Step 11: 跑测试 + 覆盖率

```bash
make test
make coverage
```

### Step 12: 更新文档

更新 `docs/api.md`：
```markdown
## POST /v1/{resources}

创建新 {resource}。

**权限**：admin

**请求头**：
- `Authorization: Bearer <token>`
- `Idempotency-Key: <uuid>` (必填)

**请求体**：
...
```

### Step 13: PR + Review

```bash
git add .
git commit -m "feat({resource}): add CRUD endpoints [PROJ-1234]"
git push origin feat/{resource}-endpoints
gh pr create --title "[PROJ-1234] Add {resource} endpoints" --body "..."
```

## 输出报告

```markdown
## 新端点创建完成

### 文件清单
- src/schemas/{resource}.py (3 schemas)
- src/models/{resource}.py (1 model)
- src/repositories/{resource}_repository.py (1 repo)
- src/services/{resource}_service.py (1 service)
- src/api/v1/{resource}.py (5 endpoints)
- migrations/versions/xxx_add_{resources}_table.py
- tests/integration/test_{resource}.py (8 tests)

### 端点
- GET /v1/{resources} — 列表
- POST /v1/{resources} — 创建
- GET /v1/{resources}/{id} — 详情
- PATCH /v1/{resources}/{id} — 更新
- DELETE /v1/{resources}/{id} — 删除

### 验证
- [x] 测试 8/8 通过
- [x] 覆盖率 85%
- [x] OpenAPI spec 完整
- [x] 文档更新

### 关联
- Jira: PROJ-1234
- PR: #456
```
