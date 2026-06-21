# Organization 实体详解

> **路径**: `src/models/organization.py`  
> **关联 API**: `/v1/organizations/*`  
> **关联表**: `organizations`

---

## 字段定义

| 字段 | 类型 | 必填 | 唯一 | 默认 | 说明 |
|------|------|------|------|------|------|
| `id` | UUID | ✅ | ✅ | uuid4() | 主键 |
| `name` | String(100) | ✅ | ❌ | - | 部门显示名 |
| `code` | String(20) | ✅ | ✅ | - | 部门编码 |
| `parent_id` | UUID | ❌ | ❌ | null | 父部门，根为 null |
| `level` | Integer | ✅ | ❌ | 1 | 层级深度（1-6），BR-005 |
| `path` | String | ✅ | ❌ | - | materialized path，便于查询 |
| `is_virtual` | Boolean | ✅ | ❌ | false | 虚拟部门（项目组等） |
| `manager_id` | UUID | ❌ | ❌ | null | 部门负责人 FK → users |
| `cost_center` | String(20) | ❌ | ❌ | null | 财务核算单元 |
| `created_at` | DateTime | ✅ | ❌ | now() | - |
| `updated_at` | DateTime | ✅ | ❌ | now() | - |
| `deleted_at` | DateTime | ❌ | ❌ | null | 软删 |
| `version` | Integer | ✅ | ❌ | 1 | 乐观锁 |

## 树形结构

```
┌─────────────────────────────────────────┐
│ Company (虚拟根, level=0)               │
│   ├─ Engineering (level=1)              │
│   │   ├─ Backend (level=2)              │
│   │   │   ├─ User Service (level=3)    │
│   │   │   └─ Order Service (level=3)   │
│   │   └─ Frontend (level=2)            │
│   ├─ Product (level=1)                  │
│   │   ├─ PM (level=2)                   │
│   │   └─ Design (level=2)               │
│   └─ Operations (level=1)               │
│       ├─ HR (level=2)                   │
│       └─ Finance (level=2)              │
└─────────────────────────────────────────┘
```

**最大深度**: 6 层（BR-005）

## Materialized Path

为高效查询子树，用 `path` 字段存储根到当前节点的路径：

```
id: 11111111-...
path: /company/engineering/backend/
```

**查询所有 Backend 子树**:
```sql
SELECT * FROM organizations 
WHERE path LIKE '/company/engineering/backend/%'
```

## 索引

```sql
CREATE UNIQUE INDEX ix_organizations_code ON organizations (code) WHERE deleted_at IS NULL;
CREATE INDEX ix_organizations_parent ON organizations (parent_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_organizations_path ON organizations USING GIST (path);
CREATE INDEX ix_organizations_manager ON organizations (manager_id) WHERE deleted_at IS NULL;
```

## 业务规则引用

| 规则 | 描述 |
|------|------|
| BR-004 | 用户单主部门 |
| BR-005 | 部门层级 ≤ 6 层 |
| BR-008 | 权限继承父部门角色 |

## 不变式

| 编号 | 不变式 |
|------|--------|
| INV-4 | 树深度 ≤ 6 |
| INV-8 | 不能删除有用户的部门（除非先迁移） |
| INV-9 | 不能删除有子部门的部门（除非先合并） |

## API 端点

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/v1/organizations` | 列表 / 树 |
| POST | `/v1/organizations` | 创建 |
| GET | `/v1/organizations/{id}` | 详情（含子树） |
| PATCH | `/v1/organizations/{id}` | 更新 |
| DELETE | `/v1/organizations/{id}` | 软删（须先迁移） |
| GET | `/v1/organizations/{id}/users` | 部门所有用户 |
| GET | `/v1/organizations/{id}/children` | 子部门列表 |

## Kafka 事件

| Topic | 触发 | Payload |
|-------|------|---------|
| `organization.created` | 创建 | `{id, name, parent_id, path}` |
| `organization.updated` | 信息变更 | `{id, changed_fields}` |
| `organization.deleted` | 软删 | `{id, deleted_at}` |
| `organization.tree_restructure` | 部门合并 / 拆分 | `{affected_ids[], changes[]}` |

## 测试场景

- ✅ 创建根部门
- ✅ 创建子部门（深度 1-6）
- ✅ 创建第 7 层失败（深度限制）
- ✅ 删除有用户的部门失败
- ✅ 删除有子部门的部门失败
- ✅ 移动部门（path 更新）
- ✅ 并发更新乐观锁冲突
