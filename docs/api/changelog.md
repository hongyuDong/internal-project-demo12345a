# API Changelog

> 记录所有影响 API 契约的变更。  
> 遵循 [Semantic Versioning](https://semver.org/)。

---

## [Unreleased]

### Added
- 计划: Webhook 签名验证（安全性增强）

## [1.4.2] - 2026-06-15

### Changed
- `GET /v1/users/{id}/permissions` 改用 ADR-0005 缓存策略
- 错误响应统一使用 RFC 7807 `application/problem+json`

### Fixed
- 修复 PATCH `/v1/users/{id}` 乐观锁版本冲突返回 409 而非 500

## [1.4.1] - 2026-05-28

### Fixed
- 修复 `POST /v1/users` 在并发情况下未正确返回 409

## [1.4.0] - 2026-05-10

### Added
- `POST /v1/users/bulk-import` 批量导入（异步任务）
- `GET /v1/jobs/{id}` 任务状态查询
- `GET /v1/users/{id}/permissions` 用户权限查询
- `POST /v1/users/{id}/deactivate` 立即停用
- `POST /v1/users/{id}/reactivate` 重新启用
- `POST /v1/permissions/check` 权限检查
- `GET /v1/organizations/{id}/children` 列子部门

### Changed
- 错误响应从 JSON 改为 `application/problem+json`（RFC 7807）
- 所有写操作强制 `Idempotency-Key` header

### Deprecated
- `/v1/users/import`（旧版），将在 1.5.0 移除

### Security
- 加入 API 速率限制（BR-018）：1000 req/min/user

## [1.3.0] - 2026-03-15

### Added
- `GET /v1/organizations/{id}/users` 列部门用户

## [1.2.0] - 2026-01-20

### Changed
- 邮箱比较改为 case-insensitive

## [1.1.0] - 2025-12-01

### Added
- 全部 API 都发 Kafka 事件（user.* / organization.*）

## [1.0.0] - 2025-09-01

### Added
- 首个 API 版本 🎉
- 20 个端点
- 完整 OpenAPI 3.0 spec

---

## 变更类型

- **Added**: 新增端点
- **Changed**: 行为变更
- **Deprecated**: 即将废弃
- **Removed**: 已删除
- **Fixed**: 修复
- **Security**: 安全修复

## 不算 API 变更

- 内部实现细节
- 性能优化（无 API 行为变化）
- 文档错误
- 测试用例变更

## 升级指南

每个版本在 `docs/upgrade/MAJOR.MINOR.md` 有详细迁移指南。
