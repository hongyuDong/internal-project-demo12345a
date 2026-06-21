# 关键 E2E 场景清单

> 必须 100% 覆盖的关键用户旅程  
> 用 Playwright 实现，跑在 staging 环境

---

## 1. 新员工入职全流程

```gherkin
Scenario: New employee full onboarding
  Given HR submits onboarding for new employee
  When HR system publishes user.onboard.requested event
  Then user-service creates user account within 30 seconds
  And user receives welcome email within 1 minute
  When new employee clicks SSO link
  And completes SSO login
  Then user status becomes "active"
  And user can access all internal systems
```

**验证步骤**:
1. HR 系统发 Kafka 消息
2. user-service 创建用户（DB 验证）
3. 验证 Kafka `user.created` 事件发出
4. 验证 notification-service 收到事件
5. 验证邮件已发（mailhog 检查）
6. SSO 模拟登录
7. 验证 `/v1/users/me` 返回新用户

---

## 2. 员工转部门

```gherkin
Scenario: Employee transfers to new department
  Given employee is in Engineering department
  When HR submits transfer to Marketing
  Then old department permissions remain for 7 days (grace period)
  And new department permissions added immediately
  And Kafka user.organization_changed event published
  And employee can access new department resources within 30 seconds
```

**验证步骤**:
1. 当前员工权限快照
2. HR 提交转部门
3. 验证两部门权限（7 天内）
4. 验证 Kafka 事件
5. 验证下游服务收到事件

---

## 3. 员工离职

```gherkin
Scenario: Employee offboarding
  Given employee is active
  When HR submits offboarding
  Then user status becomes "disabled" within 10 seconds
  And all sessions/tokens are revoked
  And employee cannot access any system
  And Kafka user.deactivated event published
  And audit log records the action
```

**验证步骤**:
1. 员工活跃，session 存在
2. HR 提交离职
3. 验证 status = disabled
4. 验证 Redis session 已清
5. 验证 JWT jti 已进黑名单
6. 验证用旧 token 调用 API 返回 401
7. 验证 Kafka 事件
8. 验证审计日志

---

## 4. 权限继承

```gherkin
Scenario: Permissions inherited from parent department
  Given employee is in "Backend" (child of "Engineering")
  And Engineering has "read_logs" permission
  When employee queries /v1/users/{id}/permissions
  Then response includes "read_logs" (inherited)
  And when Engineering's permissions are revoked
  Then employee's permissions update within 5 minutes
```

---

## 5. 批量导入 1000 用户

```gherkin
Scenario: Bulk import 1000 users
  Given admin uploads CSV with 1000 valid rows
  When POST /v1/users/bulk-import
  Then return 202 with job_id within 1 second
  And job completes within 5 minutes
  And 1000 users are created
  And 1000 user.created events published
  And admin can poll job status
```

---

## 6. 软删 + GDPR 删除

```gherkin
Scenario: GDPR right to be forgotten
  Given employee exists with PII
  When GDPR deletion request received
  And legal approves
  Then user soft-deleted (deleted_at set)
  And PII fields anonymized
  And audit log records deletion
  And data still queryable for compliance audit
```

---

## 7. SSO Token 过期 / 刷新

```gherkin
Scenario: Access token expired, refresh successful
  Given user has valid refresh token
  When access token expires
  Then API returns 401 with token_expired error
  When client calls /v1/auth/refresh
  Then new access token + refresh token returned
  And user can continue working
```

---

## 8. 限流触发

```gherkin
Scenario: Rate limit exceeded
  Given user makes 1000 API calls in 1 minute
  When user makes 1001st call
  Then return 429 Too Many Requests
  And Retry-After header set
  And user can resume after waiting
```

---

## 9. 数据库故障降级

```gherkin
Scenario: DB unavailable - readonly mode
  Given DB primary is unavailable
  When system detects DB failure
  Then service switches to readonly mode
  And POST/PATCH/DELETE return 503
  And GET endpoints return cached data (if available)
  And status page updated
```

---

## 10. 缓存命中率突降

```gherkin
Scenario: Cache hit rate drops
  Given cache-bypass flag is enabled
  When user calls API
  Then DB is queried directly (no cache)
  And response is correct (same as cached)
  And response time may be slower
  When cache-bypass flag is disabled
  Then cache resumes
```

---

## 实现要点

### Playwright 配置

```python
# tests/e2e/conftest.py
import pytest
from playwright.async_api import async_playwright


@pytest.fixture(scope="session")
async def browser():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        yield browser
        await browser.close()


@pytest.fixture
async def context(browser):
    context = await browser.new_context()
    yield context
    await context.close()
```

### 测试运行

```bash
# 本地
pytest tests/e2e/ --headed

# CI（headless）
pytest tests/e2e/ --browser chromium

# 慢速调试
pytest tests/e2e/ --headed --slowmo=1000
```

### 报告

```bash
pytest tests/e2e/ --alluredir=./allure-results
allure serve ./allure-results
```

---

## 失败时行动

| 失败 | 行动 |
|------|------|
| 单个测试失败 | 看 trace + 截图，定位修复 |
| 多个测试失败 | 可能是 staging 环境问题，先检查 |
| 持续失败 | P0 事故，暂停部署 |

---

## 新增 E2E 测试 checklist

- [ ] 真实用户场景（不是单元测试的复制）
- [ ] 端到端（穿越所有依赖）
- [ ] 独立可重跑
- [ ] < 5 分钟完成
- [ ] 失败信息清晰
- [ ] PR 评审通过
