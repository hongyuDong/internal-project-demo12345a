# 产品需求文档 (PRD)

> **项目**: internal-user-service  
> **版本**: v1.4  
> **最后更新**: 2026-06-21  
> **Owner**: @user-service-pm  
> **Status**: 🟢 Living Document

---

## 1. 愿景 (Vision)

成为公司内部**统一的身份与权限基础设施**，让所有内部系统在 5 分钟内接入员工、组织、权限能力，**消除各系统重复造轮子**。

## 2. 目标用户 (Target Users)

| 角色 | 占比 | 核心痛点 | 我们的解法 |
|------|------|----------|----------|
| **HR** | 5% | 入离职流程散落在多个系统 | 单一入口 + 事件广播 |
| **部门 Admin** | 10% | 权限调整走 Excel 审批 | 可视化权限树 + 一键提交 |
| **普通员工** | 70% | 改个密码要走工单 | 自助服务 + SSO |
| **系统开发者** | 15% | 每个系统都写一套 auth | 标准化 gRPC + SDK |

## 3. 核心场景 (Core Scenarios)

### Scenario 1: 新员工入职
1. HR 在 HR 系统提交入职单（含基本信息 + 部门 + 直属上级）
2. HR 系统调用 `POST /v1/users/batch-import` 或发 Kafka 事件
3. user-service 自动创建账号 + 分配默认权限 + 触发 welcome 邮件
4. 同步广播 `user.created` 事件给所有依赖方
5. 员工收到欢迎邮件，SSO 登录成功

**SLO**: 入职到可用 ≤ 5 分钟

### Scenario 2: 员工转部门
1. HR 在 HR 系统提交调岗
2. 旧部门权限自动 revoke（保留 7 天 grace period）
3. 新部门权限自动 grant
4. 同步广播 `user.organization_changed`
5. 审计日志写入 audit-service

**SLO**: 调岗到生效 ≤ 30 秒

### Scenario 3: 员工离职
1. HR 在 HR 系统提交离职
2. **立即** disable 所有 session + token
3. 软删用户（保留审计数据）
4. 90 天后归档冷存储
5. 广播 `user.deactivated`

**SLO**: 离职到失效 ≤ 10 秒

## 4. 非目标 (Non-Goals)

| 不做 | 原因 |
|------|------|
| ❌ 客户用户管理 | 那是 customer-id-service 的事 |
| ❌ 支付/计费 | 走 billing-service |
| ❌ 单点登录外部 IdP | 只对接公司 SSO |
| ❌ 多租户 | 内部服务，无租户概念 |
| ❌ 工作流引擎 | 走 jira + 人工审批 |

## 5. 关键指标 (KPIs)

| 指标 | 当前 | 目标 | 衡量方式 |
|------|------|------|----------|
| API 可用性 | 99.5% | 99.95% | Prometheus |
| P99 延迟（读） | 250ms | 100ms | Grafana |
| P99 延迟（写） | 600ms | 300ms | Grafana |
| 入职到可用时间 | 8 分钟 | 5 分钟 | E2E 监控 |
| 自助服务覆盖率 | 40% | 80% | 工单系统分析 |

## 6. 约束 (Constraints)

### 6.1 合规
- **GDPR / CCPA**: PII 数据必须可被用户查询 / 删除
- **SOC2 Type II**: 全链路审计
- **等保三级**: 数据库加密 + 操作审计
- **公司数据政策**: PII 不出公司内网

### 6.2 技术
- 必须用 PostgreSQL（公司规范）
- 必须有 OpenAPI 3.1 spec
- 必须接 Prometheus + Grafana
- 必须支持 K8s 部署（namespace: user-service）

### 6.3 业务
- SLA: 工作日 09:00-21:00 可用性 ≥ 99.95%
- P0 事故响应 ≤ 5 分钟（PagerDuty）
- 数据备份：每日全量 + 每 15 分钟增量
- 留存：用户数据 7 年，审计日志 7 年

## 7. 路线图 (Roadmap)

| 季度 | 主题 | 关键交付 |
|------|------|----------|
| Q1 2026 | 稳定化 | P99 < 300ms，可用性 99.9% |
| Q2 2026 | 智能化 | AI 异常权限检测、自动清理 |
| Q3 2026 | 联邦化 | 跨地域多活 |
| Q4 2026 | 平台化 | 一站式开发者门户 |

详见 `docs/project/roadmap.md`

## 8. 关联文档

- **架构总览**: `docs/architecture/overview.md`
- **业务规则**: `docs/requirements/business-rules.md`
- **术语表**: `docs/domain/glossary.md`
- **当前 Sprint**: `docs/project/sprint-backlog.md`
- **架构决策**: `docs/architecture/adr/`

---

**变更日志**

| 版本 | 日期 | 作者 | 变更 |
|------|------|------|------|
| v1.0 | 2025-08-15 | @pm-team | 初版 |
| v1.1 | 2025-10-20 | @pm-team | 加入场景 2、3 |
| v1.2 | 2026-01-15 | @pm-team | 更新 KPIs |
| v1.3 | 2026-04-01 | @pm-team | 加入非目标 |
| v1.4 | 2026-06-21 | @pm-team | 季度路线图调整 |
