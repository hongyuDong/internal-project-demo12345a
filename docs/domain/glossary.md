# 业务术语表 (Glossary)

> **最后更新**: 2026-06-21  
> **维护者**: @user-service-product  
> 任何团队成员（包括 Claude）都必须熟读本文。

---

## A

### Account（账号）
用户在系统中可登录的实体。每个 Account 关联 0 或 1 个 User。
- 字段: `id`, `email`, `status` (active / dormant / disabled)
- 状态: active / dormant / disabled / pending_verification

### Admin
具有管理权限的特殊角色，可修改其他用户权限。
- 实现: RBAC role = `admin`
- 创建: 仅 EM 可创建

### Audit Log（审计日志）
所有敏感操作的不可篡改记录。
- 存储: Kafka `audit.events` topic
- 字段: timestamp, actor_id, action, target, ip, result

### Authentication（认证）
确认用户身份的过程。本服务**不直接认证**，全部委托 SSO。
- 实现: JWT 验签 + 用户查询

### Authorization（授权）
确认用户可访问资源的过程。本服务负责 RBAC + ABAC 评估。
- 实现: 中间件 `require_role(role)` + 实时 DB 查询

## B

### Bulk Import（批量导入）
通过 CSV 文件一次创建 / 更新多个用户。
- API: `POST /v1/users/bulk-import`
- 限制: 单次最多 10,000 行
- 处理: 异步任务 + Kafka

## C

### Cache Invalidation（缓存失效）
更新 DB 后清除 Redis 缓存的机制。
- 实现: 写后失效（write-through invalidation）
- TTL: 5 分钟兜底

### Co-Manager（共同上级）
除直属上级外，可代理部分权限的同事。
- 用途: 上级休假期间
- 权限范围: 仅其下属的审批操作

### Custodian（数据管理员）
负责某个数据域的合规和保护的角色。
- 例: HR Custodian 负责所有员工 PII

## D

### Department（部门）
组织架构的节点。
- 字段: `id`, `name`, `parent_id`, `level` (1-6)
- 类型: official / virtual（项目组等临时组织）

### Dormant Account（休眠账户）
**180 天未登录**的账户。
- 处理: 自动 disable，需 HR / Admin 唤醒
- 数据: 保留，只是不允许登录

## E

### Employee（员工）
公司正式员工（区别于外包 / 实习生 / 离职员工）。
- 标志: `employee_type = 'full_time'`
- 字段: employee_id, hire_date, manager_id

### Event Sourcing（事件溯源）
通过 Kafka 事件流同步数据到下游的设计模式。
- Topic 命名: `{resource}.{action}` 如 `user.created`
- 顺序保证: 同 `user_id` 必须同 partition

## F

### Feature Flag（功能开关）
通过配置启用 / 禁用某个功能，无需重新部署。
- 工具: LaunchDarkly（公司标准）
- 命名: `user-service.<feature>`

## G

### Grace Period（宽限期）
某操作生效前的等待期。
- 例: 转部门时旧权限保留 7 天
- 例: 离职时数据保留 90 天

## H

### Hierarchy（层级）
组织架构的树形结构。
- 深度: 最多 6 层
- 根: "company" 虚拟节点

## I

### Idempotency Key（幂等键）
防止重复操作的唯一标识。
- 必填: 写操作 Header
- TTL: 24 小时
- 冲突: 返回之前的响应

### Internal User（内部用户）
公司员工。对应 External User（外部客户，走其他服务）。

## J

### JWT (JSON Web Token)
SSO 颁发的认证令牌。
- 算法: RS256
- 过期: 1 小时
- 刷新: refresh token 30 天

## L

### LDAP
公司 Active Directory，SSO 后端。
- 属性: email, displayName, department, employeeID
- 同步: SSO 登录时实时查询

## M

### Manager（直属上级）
员工的直接汇报对象。
- 字段: `manager_id`
- 约束: 必须同部门（BR-006）
- 数量: 1 个（不允许多 manager，可通过 Co-Manager 补充）

## O

### Onboarding（入职）
新员工从入职单到可用账号的全流程。
- 时长: ≤ 5 分钟（BR-014）
- 步骤: HR 提交 → user-service 创建 → 邮件通知 → SSO 登录

### Offboarding（离职）
员工从离职申请到账号完全失效的全流程。
- 时长: ≤ 10 秒失效（BR-014）
- 步骤: HR 提交 → 立即失效 → 90 天归档 → 7 年后硬删

## P

### PII (Personally Identifiable Information)
个人可识别信息。
- 字段: email, phone, id_card, address, photo
- 处理: 加密存储（BR-011）、访问审计、用户可查询 / 删除

### Permission（权限）
对某个资源的访问权。
- 类型: read / write / admin
- 粒度: resource-level（按 ID 隔离）

### Primary Department（主部门）
员工的主要所属部门。
- 数量: 仅 1 个
- 变更: 走 HR 系统

## R

### RBAC (Role-Based Access Control)
基于角色的访问控制。
- 角色: employee / manager / admin / super_admin
- 实现: 中间件 + DB 关联表

### Retention（留存）
数据保留期限。
- 用户数据: 7 年
- 审计日志: 7 年
- 软删账户: 7 年

## S

### SAML
SSO 协议标准。
- 公司 SSO: `sso.company.com`

### Session（会话）
用户登录后的服务端状态。
- 存储: Redis
- 过期: 1 小时滑动
- revoke: 立即生效

### Soft Delete（软删）
标记删除而非物理删除。
- 字段: `deleted_at`
- 查询: 默认过滤 `deleted_at IS NULL`
- 硬删: 7 年后 + 法务审批

### SSO (Single Sign-On)
单点登录。
- 公司 SSO: 唯一认证方式（BR-003）
- 协议: SAML 2.0

## T

### Token
访问凭证。
- 类型: access (1h) / refresh (30d)
- 存储: HttpOnly Cookie
- revoke: 写入 Redis 黑名单

## U

### User（用户）
系统的核心实体。
- 一个 User 对应一个 Account（不一定，反过来不成立）
- 字段: id, email, name, employee_id, primary_department_id, status, ...

## V

### Virtual Department（虚拟部门）
项目组 / 临时组织，非 HR 创建的正式部门。
- 字段: `is_virtual = true`
- 例: "世界杯活动项目组"

---

## Claude / AI 必读指南

**Claude 在回答任何业务问题前必须确认**：
1. 术语表中查不到的术语，**先问用户**，不擅自定义
2. 引用业务规则时必须使用 `BR-NNN` 编号
3. 涉及状态变更时，引用对应生命周期（onboarding / offboarding / etc）
4. 修改本文件需通过 PR review + PM 批准

---

## 维护流程

1. PM / Tech Lead 起草新术语 / 修改
2. PR 到 `main` 分支
3. @user-service-product 评审
4. 合并后通知 `#user-service-dev`
