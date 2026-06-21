# User 实体详解

> **路径**: `src/models/user.py`  
> **关联 API**: `/v1/users/*`  
> **关联表**: `users`  
> **最后更新**: 2026-06-21

---

## 字段定义

| 字段 | 类型 | 必填 | 唯一 | 默认 | 说明 |
|------|------|------|------|------|------|
| `id` | UUID | ✅ | ✅ | uuid4() | 主键 |
| `email` | String(255) | ✅ | ✅ | - | 小写存储，BR-001 |
| `email_verified` | Boolean | ❌ | ❌ | false | SSO 验证后置 true |
| `name` | String(100) | ✅ | ❌ | - | 显示名 |
| `employee_id` | String(10) | ✅ | ✅ | - | E0NNNNNNNN，BR-002 |
| `phone` | EncryptedString | ❌ | ❌ | null | PII 加密，BR-011 |
| `id_card` | EncryptedString | ❌ | ❌ | null | PII 加密 |
| `status` | Enum | ✅ | ❌ | pending_verification | 见状态机 |
| `primary_department_id` | UUID | ✅ | ❌ | - | FK → organizations |
| `manager_id` | UUID | ❌ | ❌ | null | FK → users，BR-006 |
| `secondary_departments` | UUID[] | ❌ | ❌ | [] | 兼职部门，最多 5 个 |
| `hire_date` | Date | ❌ | ❌ | null | 入职日期 |
| `last_login_at` | DateTime | ❌ | ❌ | null | 用于 dormant 检测 |
| `created_at` | DateTime | ✅ | ❌ | now() | - |
| `updated_at` | DateTime | ✅ | ❌ | now() | onupdate |
| `deleted_at` | DateTime | ❌ | ❌ | null | 软删标记 |
| `deactivated_at` | DateTime | ❌ | ❌ | null | 离职时间 |
| `dormant_at` | DateTime | ❌ | ❌ | null | 进入休眠时间 |
| `version` | Integer | ✅ | ❌ | 1 | 乐观锁 |

## 关联

```
User (N) ──> (1) Organization [primary]
User (N) ──> (0..1) User [manager]  
User (N) <──> (N) Organization [secondary]
User (N) ──> (N) Role
User (1) ──> (N) UserSession
User (1) ──> (N) UserAuditLog
User (1) ──> (N) Permission (effective)
```

## 状态机

详见 [domain-model.md](../domain-model.md#userstatus)

| 状态 | 进入条件 | 退出条件 |
|------|----------|----------|
| `pending_verification` | 创建时 | 首次 SSO 成功 |
| `active` | SSO 验证 / 唤醒 | 180d 未登录 / 离职 / 禁用 |
| `dormant` | 180d 未登录 | 30d 后未醒 / 主动唤醒 |
| `disabled` | 离职 / Admin 禁用 / 休眠超时 | 主动唤醒（需 admin）|
| (deleted) | soft delete `deleted_at` | 7 年后物理删除 |

## 索引

```sql
-- 唯一索引
CREATE UNIQUE INDEX ix_users_email ON users (LOWER(email)) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX ix_users_employee_id ON users (employee_id);

-- 普通索引
CREATE INDEX ix_users_primary_department ON users (primary_department_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_users_manager ON users (manager_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_users_status ON users (status) WHERE deleted_at IS NULL;
CREATE INDEX ix_users_last_login ON users (last_login_at) WHERE status = 'active';
CREATE INDEX ix_users_deleted ON users (deleted_at) WHERE deleted_at IS NOT NULL;
```

## 不变式

| 编号 | 不变式 |
|------|--------|
| INV-1 | 邮箱唯一（忽略大小写，不含软删） |
| INV-2 | manager 必须同部门或为高管 |
| INV-3 | 至少有一个 role（默认 `employee`） |
| INV-5 | 不能删除自己（应用层） |

## 业务规则引用

| 规则 | 描述 |
|------|------|
| BR-001 | 邮箱唯一性 |
| BR-002 | 工号唯一性 |
| BR-007 | 默认最小权限 |
| BR-011 | PII 加密 |
| BR-012 | 软删 |
| BR-014 | 离职即时失效 |
| BR-015 | 休眠账户清理 |

## API 端点

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/v1/users` | 列表（cursor 分页） |
| POST | `/v1/users` | 创建 |
| GET | `/v1/users/{id}` | 详情 |
| PATCH | `/v1/users/{id}` | 部分更新 |
| DELETE | `/v1/users/{id}` | 软删 |
| POST | `/v1/users/bulk-import` | 批量导入 |

## Kafka 事件

| Topic | 触发时机 | Payload |
|-------|----------|---------|
| `user.created` | 创建成功 | `{id, email, name, department_id, ...}` |
| `user.updated` | 信息变更 | `{id, changed_fields, ...}` |
| `user.deleted` | 软删 | `{id, deleted_by, reason}` |
| `user.deactivated` | 离职 | `{id, deactivated_at, ...}` |
| `user.organization_changed` | 转部门 | `{id, old_dept, new_dept, ...}` |

## 测试覆盖目标

- 单元测试: ≥ 85%
- 集成测试: 所有 API 端点 + 所有状态转换
- 性能测试: 10000 用户列表 P99 < 200ms
