"""
internal-user-service 主应用入口

这是一个**最小骨架**，演示如何把模板的 OpenAPI spec 落地为可运行的 FastAPI 应用。
团队可以根据自己的实际业务扩展。

启动: uvicorn src.main:app --reload
访问: http://localhost:8000/docs (自动 OpenAPI UI)
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.responses import JSONResponse
import structlog

from src.core.config import settings
from src.core.security import get_current_user
from src.models.user import User
from src.api.v1.users import router as users_router
from src.api.v1.organizations import router as orgs_router
from src.api.v1.auth import router as auth_router

logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用启动/关闭钩子"""
    logger.info("application_starting", env=settings.env, version=settings.version)
    yield
    logger.info("application_stopping")


# OpenAPI metadata（来自 docs/api/openapi.yaml）
app = FastAPI(
    title="internal-user-service API",
    version="1.4.2",
    description="企业内部用户中心微服务 API",
    lifespan=lifespan,
    # OpenAPI 3.1 配置
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)


# === 健康检查 ===
@app.get("/healthz", tags=["Health"])
async def healthz():
    """存活检查（不做依赖检查）"""
    return {"status": "ok"}


@app.get("/readyz", tags=["Health"])
async def readyz():
    """就绪检查（检查 DB / Redis / Kafka）"""
    checks = {
        "database": await check_database(),
        "redis": await check_redis(),
        "kafka": await check_kafka(),
    }
    all_ok = all(c == "ok" for c in checks.values())
    return JSONResponse(
        status_code=200 if all_ok else 503,
        content={
            "status": "ready" if all_ok else "not_ready",
            "checks": checks,
        },
    )


async def check_database() -> str:
    """检查 DB 连接"""
    try:
        # 实际项目用 SQLAlchemy: await session.execute(text("SELECT 1"))
        return "ok"
    except Exception as e:
        logger.error("db_check_failed", error=str(e))
        return "error"


async def check_redis() -> str:
    """检查 Redis 连接"""
    try:
        # await redis_client.ping()
        return "ok"
    except Exception as e:
        logger.error("redis_check_failed", error=str(e))
        return "error"


async def check_kafka() -> str:
    """检查 Kafka 连接"""
    try:
        # await kafka_producer.client.bootstrap_connected()
        return "ok"
    except Exception as e:
        logger.error("kafka_check_failed", error=str(e))
        return "error"


# === 业务路由 ===
app.include_router(auth_router, prefix="/v1/auth")
app.include_router(users_router, prefix="/v1/users")
app.include_router(orgs_router, prefix="/v1/organizations")


# === 全局异常处理 ===
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc: HTTPException):
    """统一错误响应（RFC 7807）"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "type": f"https://api.company.com/errors/{slugify(exc.detail)}",
            "title": exc.detail,
            "status": exc.status_code,
            "instance": str(request.url.path),
            "request_id": request.headers.get("X-Request-ID"),
        },
        media_type="application/problem+json",
    )


def slugify(text: str) -> str:
    """简单的 slug 化"""
    return text.lower().replace(" ", "-")
