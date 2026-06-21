# Permission / Role 实体详解

> **路径**: `src/models/permission.py`, `src/models/role.py`  
> **关联 API**: `/v1/roles/*`, `/v1/permissions/*`

---

## RBAC 模型

```
┌────────────────┐      ┌─────────────────┐      ┌──────────────────┐
│     USER       │      │      ROLE       │      │   PERMISSION     │
├────────────────┤      ├─────────────────┤      ├──────────────────┤
│ id             │      │ id              │      │ id               │
│ email          │      │ name            │      │ resource         │
│ ...            │      │ description     │      │ action           │
└────────┬───────┘      └────────┬────────┘      │ scope (optional) │
         │                       │                └────────┬─────────┘
         │ user_roles (N:N)     │ role_permissions (N:N)    │
         └───────────────────────┴────────────────────────────┘
```

## 内置角色

| 角色 | 描述 | 默认权限 |
|------|------|----------|
| `super_admin` | 超级管理员（EM） | 所有权限 |
| `admin` | 部门管理员 | 用户管理、权限分配（限本部门及子部门） |
| `manager` | 团队主管 | 查看下属、审批调岗 |
| `employee` | 普通员工 | 查看自己 |

## 权限定义格式

```yaml
# 格式: resource:action[:scope]
- users:read           # 读用户
- users:write          # 写用户
- users:delete         # 删用户
- users:read:dept      # 读本部门用户
- permissions:grant    # 授予权限
- audit:read           # 读审计日志
```

## Permission 字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | UUID | ✅ | 主键 |
| `resource` | String(50) | ✅ | 资源名 |
| `action` | String(20) | ✅ | read / write / delete / admin |
| `scope` | String(20) | ❌ | dept / self / all，默认 all |
| `description` | String(200) | ❌ | 说明 |
| `created_at` | DateTime | ✅ | - |

唯一约束: `(resource, action, scope)`

## Role 字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | UUID | ✅ | 主键 |
| `name` | String(50) | ✅ | 唯一 |
| `description` | String(200) | ❌ | - |
| `is_system` | Boolean | ✅ | 内置角色不可删 |
| `created_at` | DateTime | ✅ | - |

## UserRole（关联表）

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | UUID | FK → users |
| `role_id` | UUID | FK → roles |
| `granted_by` | UUID | 授权人 |
| `granted_at` | DateTime | 授权时间 |
| `expires_at` | DateTime | 过期时间（可选） |

主键: `(user_id, role_id)`

## 权限继承计算

```
effective_permissions(user) = 
    直接权限（user_permissions）
  ∪ 主部门角色的权限
  ∪ 所有父部门角色的权限
  ∪ 经理角色（manager）的权限
```

**缓存**: Redis 5 分钟 TTL
**失效**: 任何权限变更立即清除缓存

## 业务规则引用

| 规则 | 描述 |
|------|------|
| BR-007 | 最小权限原则 |
| BR-008 | 权限继承（仅主部门及父部门） |
| BR-009 | 30 秒内生效 |
| BR-010 | 不能删除自己的 admin |

## API 端点

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/v1/users/{id}/permissions` | 用户的有效权限 |
| POST | `/v1/users/{id}/roles` | 授予角色 |
| DELETE | `/v1/users/{id}/roles/{role_id}` | 撤销角色 |
| GET | `/v1/roles` | 角色列表 |
| POST | `/v1/permissions/check` | 检查权限（ABAC） |

## Kafka 事件

| Topic | 触发 | Payload |
|-------|------|---------|
| `permission.granted` | 授权 | `{user_id, role_id, granted_by, ...}` |
| `permission.revoked` | 撤销 | `{user_id, role_id, revoked_by}` |
| `permission.expired` | 自动过期 | `{user_id, role_id}` |

## 测试场景

- ✅ 内置角色不可删除 / 修改
- ✅ 撤销 admin 角色后 API 立即 403
- ✅ 权限继承计算正确（多级部门）
- ✅ 权限缓存正确失效
- ✅ 过期时间到期自动撤销
- ✅ 不能撤销自己的 admin
