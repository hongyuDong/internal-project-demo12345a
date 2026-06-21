# Task: 用户登录 P99 优化 [PROJ-1001]

> **开始时间**: 2026-06-21
> **负责人**: @zhangsan
> **关联工单**: PROJ-1001
> **状态**: 🟡 进行中
> **Sprint**: 2026-06-21 ~ 2026-07-04

> 📌 这是一个**示例**任务计划，复制此模板替换为自己的任务。

---

## 目标 (Goal)

将 `/v1/auth/me` 和 `/v1/users/me` 的 P99 延迟从 800ms 降至 200ms 以内。

## 验收标准 (Acceptance Criteria)

### 必选
- [ ] **AC-1**: P99 延迟 ≤ 200ms（基线 800ms）
- [ ] **AC-2**: 错误率不上升（保持 < 0.1%）
- [ ] **AC-3**: 早高峰（9:00-9:30）1000 并发无超时
- [ ] **AC-4**: 缓存命中率 ≥ 90%
- [ ] **AC-5**: 所有登录行为有审计日志

### 加分
- [ ] **AC-6**: 自动压测集成到 CI（性能回归防护）

## 子任务 (Subtasks)

### 阶段 1: 调研（30 min）

- [ ] **1.1** 现状 profile（15 min）🟢
  - 用 `py-spy record` profile 10 分钟流量
  - 完成标准: notes.md 有 profile 数据截图
- [ ] **1.2** 读相关 ADR 和代码（15 min）🟢
  - 读 `docs/architecture/adr/0003-jwt-vs-session.md`
  - 读 `src/services/auth_service.py`
  - 完成标准: notes.md 列出 3 个慢热点

### 阶段 2: 设计（1 h）

- [ ] **2.1** 评估缓存方案（30 min）🟡
  - 选项 A: Redis 缓存 user 信息（5 min TTL）
  - 选项 B: Redis 缓存 permissions（5 min TTL）
  - 选项 C: JWT claims 直接带 permissions（无状态）
  - 完成标准: ADR-0005 草案，附决策矩阵
- [ ] **2.2** 写 ADR（30 min）🟡
  - 文档：`docs/architecture/adr/0005-permission-cache.md`
  - 完成标准: 已 commit，2 个 Approve

### 阶段 3: 实施（2 h）

- [ ] **3.1** 加 Redis 缓存层（45 min）🟡
  - `src/core/cache.py`：通用 cache wrapper
  - `src/services/auth_service.py`：集成缓存
  - 完成标准: 单元测试 5 个通过
- [ ] **3.2** 写后失效逻辑（30 min）🟡
  - 用户更新时 DEL cache
  - 权限变更时 DEL cache
  - 完成标准: 失效逻辑测试通过
- [ ] **3.3** 集成审计（15 min）🟢
  - 登录成功 / 失败都发 Kafka
  - 完成标准: Sentry 收到事件

### 阶段 4: 验证（30 min）

- [ ] **4.1** 单元测试 + 集成测试（10 min）🟢
  - 完成标准: 覆盖率 ≥ 85%
- [ ] **4.2** 部署 staging + 冒烟（10 min）🟢
  - 完成标准: staging 环境 P99 < 250ms
- [ ] **4.3** PM 验收（10 min）🟢
  - 完成标准: PM 在 staging 验收签字

## 决策记录 (Decisions)

- **选择 Redis 缓存 user 信息**（不是 Memcached）
  - 原因：公司已有 Redis 基础设施
  - 数据结构：String → JSON（user data）
  - TTL：5 分钟 + 写后失效

- **不用 JWT claims 带 permissions**
  - 原因：JWT payload 增大影响性能 + 撤销复杂

- **TTL 选 5 分钟不是 1 分钟**
  - 原因：1 分钟命中率 70%，5 分钟 90%
  - 折中：BR-009 要求 ≤ 30 秒生效，写后失效兜底

## 风险 (Risks)

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| Redis 故障 | 🟡 中 | API 慢 5x | 自动降级到直查 DB |
| 缓存数据不一致 | 🟢 低 | 安全问题 | 写后失效 + HMAC 校验 |
| P99 目标不达 | 🟡 中 | sprint 失败 | 先 staging 验证再上 prod |

## 依赖 (Dependencies)

- **依赖**：PROJ-1005（权限缓存重构，姊妹工单）
- **阻塞**：PROJ-1010（AI 异常权限检测）

## 回滚方案 (Rollback)

```bash
# 1. 关闭 feature flag
ld flag set user-service.permission-cache --enabled false

# 2. 回滚部署
kubectl rollout undo deployment/user-service -n user-service-prod

# 3. 监控 30 分钟
# - P99 应恢复到 ~800ms（说明回滚成功）
# - 错误率不上升
```

## 关联文档

- 用户故事：`docs/requirements/user-stories/PROJ-1001-login.md`
- ADR：`docs/architecture/adr/0005-permission-cache.md`
- Runbook：`docs/runbook/redis-down.md`（如缓存故障）
- 关联 BR：BR-009（30 秒生效）

---

## 进度同步

详见 `.planning/current/progress.md`（每日更新）
