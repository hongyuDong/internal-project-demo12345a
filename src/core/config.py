"""
配置管理

所有配置从环境变量读取，**绝不**硬编码。
敏感配置（密钥、密码）从 Vault 读取（生产环境）。
"""

from functools import lru_cache
from pydantic import BaseSettings, Field


class Settings(BaseSettings):
    """应用配置（pydantic-settings）"""

    # === 基础 ===
    env: str = Field(default="local", env="ENV")  # local / dev / staging / prod
    version: str = "1.4.2"
    debug: bool = Field(default=False, env="DEBUG")

    # === API ===
    api_prefix: str = "/v1"
    cors_origins: list[str] = Field(default=["http://localhost:3000"], env="CORS_ORIGINS")
    rate_limit_per_minute: int = 1000  # BR-018

    # === 数据库 ===
    database_url: str = Field(..., env="DATABASE_URL")
    db_pool_size: int = 20
    db_max_overflow: int = 10
    db_echo: bool = False

    # === Redis ===
    redis_url: str = Field(..., env="REDIS_URL")
    redis_cache_ttl: int = 300  # 5 分钟（ADR-0005）

    # === Kafka ===
    kafka_bootstrap_servers: str = Field(..., env="KAFKA_BOOTSTRAP_SERVERS")
    kafka_topic_prefix: str = "user-service"

    # === SSO / JWT ===
    sso_jwks_url: str = Field(..., env="SSO_JWKS_URL")
    sso_issuer: str = Field(default="sso.company.com", env="SSO_ISSUER")
    jwt_audience: str = Field(default="user-service", env="JWT_AUDIENCE")

    # === Vault（密钥管理） ===
    vault_url: str = Field(..., env="VAULT_URL")
    vault_token: str = Field(..., env="VAULT_TOKEN")

    # === 监控 ===
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    otel_endpoint: str = Field(default="", env="OTEL_EXPORTER_OTLP_ENDPOINT")

    # === Feature Flags ===
    cache_bypass_enabled: bool = Field(default=False, env="FEATURE_CACHE_BYPASS")
    readonly_mode: bool = Field(default=False, env="FEATURE_READONLY_MODE")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """获取配置单例"""
    return Settings()


# 全局快捷访问
settings = get_settings()
