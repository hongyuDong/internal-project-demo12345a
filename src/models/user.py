"""
User SQLAlchemy 模型

完整字段定义见 docs/domain/entities/user.md
"""

from datetime import datetime
from uuid import UUID, uuid4
from sqlalchemy import String, DateTime, Integer, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """所有模型的基类"""
    pass


class User(Base):
    """
    User 实体。

    完整规范：docs/domain/entities/user.md
    不变式（INV-1 ~ INV-5）：docs/domain/domain-model.md
    业务规则（BR-001, BR-002, BR-007）：docs/requirements/business-rules.md
    """
    __tablename__ = "users"

    # === 主键 ===
    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True, default=uuid4)

    # === 基本信息 ===
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    email_verified: Mapped[bool] = mapped_column(default=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)

    # === 业务标识 ===
    employee_id: Mapped[str] = mapped_column(String(10), unique=True, nullable=False)
    # 格式: E0NNNNNNNN (BR-002)

    # === PII（加密字段，BR-011）===
    phone_enc: Mapped[bytes | None] = mapped_column(nullable=True)  # AES-256-GCM
    id_card_enc: Mapped[bytes | None] = mapped_column(nullable=True)

    # === 状态 ===
    status: Mapped[str] = mapped_column(
        String(20),
        default="pending_verification",
        # pending_verification / active / dormant / disabled
    )

    # === 组织关系 ===
    primary_department_id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True))
    manager_id: Mapped[UUID | None] = mapped_column(PG_UUID(as_uuid=True), nullable=True)

    # === 时间戳 ===
    hire_date: Mapped[datetime | None] = mapped_column(nullable=True)
    last_login_at: Mapped[datetime | None] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    deactivated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    dormant_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # === 乐观锁 ===
    version: Mapped[int] = mapped_column(Integer, default=1)

    def __repr__(self) -> str:
        return f"<User {self.email} ({self.status})>"
