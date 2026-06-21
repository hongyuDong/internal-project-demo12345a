# 测试策略总览

> user-service 的测试方法论和最佳实践。

---

## 🎯 测试金字塔

```
           /\
          /E2E\           5-10 个场景，Playwright
         /─────\          慢（30s-2min），覆盖关键路径
        /───────\
       / 集成测试 \       50-100 个，TestClient + 真 DB
      /─────────────\    中等（5-30s），覆盖 API + 流程
     /───────────────\
    /    单元测试      \    500+ 个，pytest + mocks
   /─────────────────────\  快（<1s），覆盖业务逻辑
```

**覆盖率目标**：

| 层 | 覆盖率 | 数量 |
|----|--------|------|
| 单元测试 | ≥ 85% | 500+ |
| 集成测试 | ≥ 70% | 50+ |
| E2E 测试 | 关键路径 100% | 5-10 |

---

## 📚 测试文档

| 文件 | 内容 |
|------|------|
| [strategy.md](strategy.md) | 完整测试策略 + 工具体系 |
| [e2e-scenarios.md](e2e-scenarios.md) | 关键 E2E 场景清单 |
| [load-testing.md](load-testing.md) | 压测方案 + 容量规划 |

---

## 🛠️ 测试工具

| 用途 | 工具 |
|------|------|
| 单元测试 | pytest |
| 集成测试 | pytest + httpx.AsyncClient + TestContainers |
| E2E | Playwright |
| 压测 | Locust + k6 |
| 覆盖率 | coverage.py + Codecov |
| Mock | pytest-mock |
| 断言 | pytest + assertpy |
| 工厂 | factory_boy |
| 时间 | freezegun |
| HTTP mock | responses / vcrpy |

---

## 📁 目录结构

```
tests/
├── unit/                          # 单元测试（500+）
│   ├── core/
│   │   ├── test_security.py
│   │   └── test_config.py
│   ├── models/
│   │   ├── test_user.py
│   │   ├── test_organization.py
│   │   └── test_permission.py
│   ├── services/
│   │   ├── test_user_service.py
│   │   ├── test_auth_service.py
│   │   └── test_permission_service.py
│   └── repositories/
│       └── test_user_repository.py
│
├── integration/                   # 集成测试（50+）
│   ├── api/
│   │   ├── test_users_api.py
│   │   ├── test_organizations_api.py
│   │   └── test_auth_api.py
│   ├── workflows/
│   │   ├── test_onboarding_flow.py
│   │   ├── test_transfer_flow.py
│   │   └── test_offboarding_flow.py
│   └── integrations/              # 外部集成
│       ├── test_sso.py
│       ├── test_kafka.py
│       └── test_vault.py
│
├── e2e/                           # E2E 测试（5-10）
│   ├── test_user_lifecycle.py
│   ├── test_permission_inheritance.py
│   └── test_bulk_import.py
│
├── performance/                   # 压测
│   ├── locustfile.py
│   └── scenarios/
│
├── conftest.py                    # 共享 fixture
├── factories/                     # 测试数据工厂
└── helpers/                       # 测试工具
```

---

## 🚦 CI 强制门禁

每个 PR 必须满足：

- [ ] 单元测试 + 集成测试全部通过
- [ ] 覆盖率 ≥ 85%
- [ ] 新代码有测试覆盖（coverage diff）
- [ ] Lint 通过（ruff + mypy）
- [ ] 安全扫描通过（bandit）
- [ ] E2E 关键路径通过（每天跑）
- [ ] 没有遗留 `pytest.mark.skip` / `xfail`

---

## 📊 测试报告

CI 自动生成：

- HTML 报告（allure）
- 覆盖率徽章
- 性能回归对比（如果启用）
- Slack 通知（失败时）

---

## 🧪 测试数据管理

### Fixture 策略

| 范围 | Fixture 位置 | 共享 |
|------|-------------|------|
| 全局 | `conftest.py` | ✅ |
| 模块 | `tests/<module>/conftest.py` | ✅ |
| 函数 | 函数参数 | ❌ |

### 数据库隔离

每个测试用**事务回滚**隔离：

```python
@pytest.fixture
async def db_session(postgres):
    async with async_session() as session:
        yield session
        await session.rollback()  # 测试后回滚
```

### 工厂模式

```python
# factories/user_factory.py
import factory
from src.models.user import User

class UserFactory(factory.Factory):
    class Meta:
        model = User
    
    email = factory.Sequence(lambda n: f"user{n}@test.com")
    name = factory.Faker("name")
    employee_id = factory.Sequence(lambda n: f"E{n:08d}")
    status = "active"
```

---

## 🎯 编写测试的最佳实践

### DO ✅

1. **测行为不测实现**
   ```python
   # ✅ 好
   assert response.json()["email"] == "test@company.com"
   
   # ❌ 坏
   assert mock_db.execute.called_with(...)
   ```

2. **一个测试一个断言**（核心断言）
   ```python
   async def test_create_user_success(...):
       r = await client.post(...)
       assert r.status_code == 201  # 核心
       # 其他断言可加但不作为失败核心
   ```

3. **使用 parametrize**
   ```python
   @pytest.mark.parametrize("email,valid", [
       ("user@example.com", True),
       ("invalid", False),
       ("", False),
   ])
   async def test_email_validation(email, valid):
       ...
   ```

4. **明确的测试名**
   ```python
   async def test_create_user_with_duplicate_email_returns_409():
       ...
   ```

### DON'T ❌

1. **不要测试 sleep**
   ```python
   # ❌
   time.sleep(2)
   assert condition
   
   # ✅
   await wait_for(condition, timeout=5)
   ```

2. **不要共享全局状态**
   ```python
   # ❌
   global_counter = 0
   
   # ✅
   @pytest.fixture
   def counter():
       return {"value": 0}
   ```

3. **不要 hardcode 时间**
   ```python
   # ❌
   assert user.created_at > "2026-01-01"
   
   # ✅
   from freezegun import freeze_time
   with freeze_time("2026-06-21"):
       ...
   ```

---

## 🔗 相关文档

- [完整测试策略](strategy.md)
- [E2E 场景](e2e-scenarios.md)
- [压测方案](load-testing.md)
- [CI/CD](../architecture/deployment.md#3-cicd-流程)
- [ADR](../architecture/adr/)
