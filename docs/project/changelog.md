# 变更日志 (CHANGELOG)

> 记录 user-service 所有用户可见的变更。  
> 格式基于 [Keep a Changelog](https://keepachangelog.com/)。

---

## [Unreleased]

### Added
- AI 异常权限检测（PROJ-1010）
- 性能压测自动化（PROJ-1025）

### Changed
- 部门变更改为异步处理（PROJ-1015）

### Fixed
- 工号校验逻辑缺陷（PROJ-1100）

## [1.4.2] - 2026-06-15

### Added
- 自助权限查询 API `/v1/me/permissions`

### Changed
- 优化 JWT 验证性能（P99 减少 30%）

### Fixed
- 修复 SSO 登出后部分依赖服务未失效

### Security
- 升级 cryptography 到 41.0.7（CVE-2024-26130）

## [1.4.1] - 2026-05-28

### Fixed
- 修复部门删除时的外键约束错误
- 修复 Redis 连接池耗尽导致 503

## [1.4.0] - 2026-05-10

### Added
- 批量导入 API `/v1/users/bulk-import`（支持 10000 行）
- 任务查询 API `/v1/jobs/{id}`
- 用户审计日志查询 API（Admin 权限）

### Changed
- 升级到 PostgreSQL 15
- 升级到 Redis 7
- 重构权限计算逻辑（性能 +50%）

### Deprecated
- `/v1/users/import`（旧版），将在 1.5.0 移除

### Security
- PII 字段加密从字段级改为列级（AES-256-GCM）
- 加入 BR-018 API 调用配额限制

## [1.3.0] - 2026-03-15

### Added
- 多部门支持（secondary_departments）
- Co-Manager 功能
- 用户头像上传（OSS）

### Changed
- 重新设计 API 错误响应（RFC 7807）
- OpenAPI spec 从 3.0 升级到 3.1

## [1.2.0] - 2026-01-20

### Added
- 软删机制（BR-012）
- 审计日志 HMAC 签名

### Changed
- 邮箱比较改为 case-insensitive

### Removed
- 移除已废弃的本地密码登录（BR-003 SSO 强制）

## [1.1.0] - 2025-12-01

### Added
- Kafka 事件总线
- 8 个下游事件订阅
- Outbox 模式保证事件最终一致

## [1.0.0] - 2025-09-01

### Added
- 首个生产版本 🎉
- 用户 CRUD API
- 组织树 API
- RBAC + ABAC 权限
- SSO 集成

---

## 变更分类

- **Added**: 新功能
- **Changed**: 现有功能变更
- **Deprecated**: 即将移除
- **Removed**: 已移除
- **Fixed**: Bug 修复
- **Security**: 安全修复

## 版本号规范

遵循 [Semantic Versioning](https://semver.org/)：
- **MAJOR**: 不兼容的 API 变更
- **MINOR**: 向后兼容的新功能
- **PATCH**: 向后兼容的 bug 修复

## 发布流程

1. Tech Lead 在 Sprint 结束前 1 天创建 release tag
2. CI 自动构建 + 部署到 staging
3. QA 冒烟测试通过
4. EM 在 release window 手动部署 prod
5. 通知 #announcements
