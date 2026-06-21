# [PROJ-1001] 用户登录流程优化

> **作者**: @pm-team  
> **创建日期**: 2026-06-15  
> **Sprint**: 2026-06-21 ~ 2026-07-04  
> **状态**: 🟡 进行中  
> **负责人**: @zhangsan  
> **优先级**: P0

---

## 用户故事

**As a** 普通员工  
**I want** 通过 SSO 一键登录所有内部系统  
**so that** 不用记多个账号密码

## 背景

当前登录流程 P99 延迟 800ms，主要瓶颈在权限查询。需要：
1. 优化权限缓存（减少 DB 查询）
2. 加 Redis session 预热
3. 异步审计日志写入

## 验收标准（详见 acceptance-criteria.md）

### AC-1: 正常登录
**Given** 用户在公司 SSO 已登录  
**When** 访问 user-service API  
**Then** ≤ 200ms 返回用户信息，含 permissions

### AC-2: SSO 登出同步
**Given** 用户在 SSO 登出  
**When** 任何依赖 user-service 的 API 调用  
**Then** ≤ 10 秒内返回 401

### AC-3: 高并发
**Given** 系统处于早高峰（9:00-9:30）  
**When** 1000 用户同时登录  
**Then** P99 ≤ 300ms，错误率 < 0.1%

### AC-4: 审计完整
**Given** 任何登录行为  
**When** 完成  
**Then** 审计日志含 user_id / IP / user_agent / 时间 / 结果

## 非验收标准
- ❌ 不做生物识别登录（公司安全政策不允许）
- ❌ 不做密码登录（BR-003 SSO 强制）
- ❌ 不做第三方登录（Google / Microsoft）

## 度量

| 指标 | 当前 | 目标 |
|------|------|------|
| P99 延迟 | 800ms | 200ms |
| 错误率 | 0.05% | < 0.1% |
| 缓存命中率 | - | > 90% |
| 并发能力 | 500/s | 2000/s |

## 技术方案

参见 `docs/architecture/adr/0005-permission-cache.md`

## 子任务（拆解）

- [x] 现状 profile（py-spy）
- [x] ADR 起草（Redis vs Memcached）
- [x] 单元测试覆盖到 85%
- [ ] 集成测试
- [ ] 部署 staging
- [ ] 压测验证
- [ ] PR review
- [ ] 部署 prod

## Definition of Done

- [ ] 所有 AC 自动化测试通过
- [ ] P99 延迟达标
- [ ] 覆盖率 ≥ 85%
- [ ] 安全审计通过（OWASP Top 10）
- [ ] PR 2 个 Approve
- [ ] 部署 staging 验证
- [ ] PM 验收签字
- [ ] 文档更新（API / Runbook / CHANGELOG）
- [ ] ADR 已写入

## 关联

- 业务规则: BR-003, BR-009, BR-013
- ADR: `docs/architecture/adr/0005-permission-cache.md`
- 关联工单: PROJ-1015（依赖）, PROJ-1018（被依赖）
- Slack: `#user-service-dev`
