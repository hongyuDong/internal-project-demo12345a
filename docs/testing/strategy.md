# 测试策略（完整版）

> 公司标准 + 项目特定规范

---

## 1. 测试目标

| 目标 | 度量 |
|------|------|
| **正确性** | 所有 AC 都覆盖 + 测试通过 |
| **回归防护** | 修改不破坏现有功能 |
| **性能保障** | 压测达标，回归测试守住 |
| **安全防护** | OWASP Top 10 覆盖 |
| **文档化** | 测试即文档，演示用法 |

---

## 2. 测试原则

### FIRST 原则

- **F**ast: 单元测试 < 1s
- **I**ndependent: 测试间无依赖
- **R**epeatable: 任何环境可重现
- **S**elf-validating: 自动化断言
- **T**imely: 与代码同步写

### 3A 原则

- **Arrange**: 准备数据
- **Act**: 执行操作
- **Assert**: 验证结果

### Test Pyramid

不要颠倒（避免"冰淇淋蛋卷反模式"：太多 E2E 太少单元）

---

## 3. 测试分层详细

### 3.1 单元测试（Unit）

**范围**: 单个函数/类，无 IO

**速度**: < 1s/测试

**数量**: 500+

**覆盖**: ≥ 85%

**例子**:
```python
# tests/unit/services/test_permission_service.py
import pytest
from unittest.mock import Mock

from src.services.permission_service import PermissionService
from src.services.exceptions import PermissionDeniedError


class TestPermissionService:
    @pytest.fixture
    def service(self):
        return PermissionService(
            user_repo=Mock(),
            org_repo=Mock(),
            role_repo=Mock(),
        )
    
    def test_calculate_user_permissions_includes_direct_roles(self, service):
        # Arrange
        user_id = uuid4()
        service.user_repo.get.return_value = Mock(
            id=user_id,
            primary_department_id=uuid4(),
        )
        service.role_repo.get_user_roles.return_value = ["employee"]
        
        # Act
        perms = service.calculate_permissions(user_id)
        
        # Assert
        assert "users:read:self" in perms
    
    def test_permission_inheritance_from_parent_dept(self, service):
        # Arrange
        dept_id = uuid4()
        parent_dept_id = uuid4()
        
        service.user_repo.get.return_value = Mock(primary_department_id=dept_id)
        service.org_repo.get_ancestors.return_value = [parent_dept_id]
        service.role_repo.get_user_roles.return_value = ["employee"]
        service.role_repo.get_dept_roles.side_effect = lambda did: (
            ["admin"] if did == parent_dept_id else []
        )
        
        # Act
        perms = service.calculate_permissions(uuid4())
        
        # Assert
        # admin 角色应包含 users:write
        assert "users:write:all" in perms
    
    def test_permission_check_denies_unauthorized(self, service):
        # Arrange
        service.user_repo.get.return_value = Mock(role_names=["employee"])
        
        # Act & Assert
        with pytest.raises(PermissionDeniedError):
            service.check(uuid4(), "users:delete:all")
```

### 3.2 集成测试（Integration）

**范围**: API + 真 DB（testcontainers）+ 真实 Redis

**速度**: 5-30s/测试

**数量**: 50-100

**覆盖**: ≥ 70%

**关键测试场景**:

| 模块 | 场景 |
|------|------|
| 用户 API | 创建 / 查询 / 更新 / 删除 / 批量导入 |
| 组织 API | CRUD + 树查询 + 层级校验 |
| 权限 API | 角色授予 / 撤销 / 检查 |
| 认证 | SSO 集成 / JWT 验证 / 注销 |
| 工作流 | 入职 / 转岗 / 离职 |
| 事件 | Kafka 发出 + 消费 |

**例子**:
```python
# tests/integration/api/test_users_api.py
import pytest
from uuid import uuid4

pytestmark = pytest.mark.asyncio


class TestCreateUser:
    async def test_success(self, client, admin_token, db_session):
        # Arrange
        payload = {
            "email": "new@company.com",
            "name": "New User",
            "employee_id": "E99999999",
            "primary_department_id": str(uuid4()),
        }
        headers = {
            "Authorization": f"Bearer {admin_token}",
            "Idempotency-Key": str(uuid4()),
        }
        
        # Act
        r = await client.post("/v1/users", json=payload, headers=headers)
        
        # Assert
        assert r.status_code == 201
        data = r.json()
        assert data["email"] == payload["email"]
        assert data["status"] == "pending_verification"
        assert data["version"] == 1
    
    async def test_duplicate_email_returns_409(self, client, admin_token, existing_user):
        payload = {
            "email": existing_user.email,
            "name": "Dup",
            "employee_id": "E99999998",
            "primary_department_id": str(uuid4()),
        }
        headers = {
            "Authorization": f"Bearer {admin_token}",
            "Idempotency-Key": str(uuid4()),
        }
        
        r = await client.post("/v1/users", json=payload, headers=headers)
        
        assert r.status_code == 409
        body = r.json()
        assert "already exists" in body["detail"].lower()
    
    async def test_missing_required_field_returns_422(
        self, client, admin_token
    ):
        payload = {"email": "x@x.com"}  # 缺 name, employee_id
        headers = {
            "Authorization": f"Bearer {admin_token}",
            "Idempotency-Key": str(uuid4()),
        }
        
        r = await client.post("/v1/users", json=payload, headers=headers)
        
        assert r.status_code == 422
```

### 3.3 E2E 测试

**范围**: 完整用户旅程

**速度**: 30s-2min/测试

**数量**: 5-10 个关键场景

**工具**: Playwright

**场景**: 见 [e2e-scenarios.md](e2e-scenarios.md)

---

## 4. 测试基础设施

### 4.1 TestContainers

```python
# tests/conftest.py
import pytest
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer


@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:15") as pg:
        yield pg


@pytest.fixture(scope="session")
def redis():
    with RedisContainer("redis:7") as r:
        yield r
```

### 4.2 Mock 策略

| 层级 | 真实 | Mock |
|------|------|------|
| 单元测试 | 几乎全部 mock | 只测逻辑 |
| 集成测试 | 真 DB + 真 Redis | SSO + Kafka |
| E2E | 全真 | 无 |

### 4.3 时间控制

```python
from freezegun import freeze_time

@freeze_time("2026-06-21 12:00:00")
def test_dormant_detection_after_180_days():
    user = create_user(...)
    # 180 天后
    with freeze_time("2026-12-18 12:00:00"):
        run_dormant_check()
        assert user.status == "dormant"
```

---

## 5. 测试覆盖率

### 5.1 覆盖率类型

| 类型 | 目标 | 工具 |
|------|------|------|
| 行覆盖 | ≥ 85% | coverage.py |
| 分支覆盖 | ≥ 75% | coverage.py |
| 函数覆盖 | ≥ 95% | coverage.py |

### 5.2 排除规则

```toml
# pyproject.toml
[tool.coverage.run]
omit = [
    "*/migrations/*",
    "*/tests/*",
    "*/__main__.py",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
]
```

### 5.3 覆盖率趋势

CI 强制覆盖率**不下降**：
- baseline: 当前 main 分支覆盖率
- PR: 必须 ≥ baseline - 0.5%

---

## 6. 性能测试

详见 [load-testing.md](load-testing.md)

---

## 7. 安全测试

### 7.1 OWASP Top 10 覆盖

| 风险 | 测试 |
|------|------|
| A01 Broken Access Control | test_auth.py + test_idor.py |
| A02 Cryptographic Failures | test_encryption.py |
| A03 Injection (SQL) | test_sql_injection.py |
| A04 Insecure Design | test_business_rules.py |
| A05 Security Misconfig | test_security_headers.py |
| A06 Vulnerable Components | bandit + safety |
| A07 Auth Failures | test_jwt_validation.py |
| A08 Software/Data Integrity | test_event_signing.py |
| A09 Logging Failures | test_audit_log.py |
| A10 SSRF | test_external_calls.py |

### 7.2 自动化工具

```bash
# SAST
bandit -r src/

# 依赖漏洞
safety check

# secret 扫描
detect-secrets scan

# License 合规
pip-licenses --fail-on="GPL;AGPL"
```

---

## 8. 故障注入测试（混沌工程）

### 8.1 季度演练

- DB 主库切换
- Redis 全节点宕机
- Kafka broker 故障
- 网络分区
- pod OOMKill

### 8.2 工具

- chaos-mesh（K8s）
- toxiproxy（DB / 网络）

### 8.3 演练 checklist

- [ ] 提前通知（演练日 1 周）
- [ ] 在 staging 环境跑（不生产）
- [ ] 验证监控告警正确触发
- [ ] 验证恢复流程顺畅
- [ ] 写演练报告

---

## 9. 持续改进

### 9.1 测试回顾（Sprint 末）

- 哪些 bug 是测试没覆盖到的？
- 哪些测试是 flaky 的？
- 哪些测试太慢？
- 哪些测试重复？

### 9.2 工具评估（季度）

- 新工具（如 Playwright vs Cypress）
- 性能提升（如 pytest-xdist 并行）
- 报告改进（如 Allure）

---

## 10. 参考

- [Google Testing Blog](https://testing.googleblog.com/)
- [Martin Fowler - Test Pyramid](https://martinfowler.com/bliki/TestPyramid.html)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [pytest 官方文档](https://docs.pytest.org/)
