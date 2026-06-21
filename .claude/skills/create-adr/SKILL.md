---
name: create-adr
description: 创建 / 更新架构决策记录（ADR），强制走模板和审批流程
---

# Create ADR

当遇到需要做架构决策时（选型 / 模式 / 重构方向），自动创建或更新 ADR。

## 何时触发

- 新技术选型（数据库 / 框架 / 中间件）
- 重大的模式变更（同步 → 异步，单体 → 微服务）
- 影响范围 > 3 个文件的重构
- 引入新依赖（npm 包 / pip 包）
- 推翻旧决策

**不触发**：
- 普通 bug fix
- UI 调整
- 文档更新
- 单文件小重构

## Step 1: 检查现有 ADR

```bash
ls docs/architecture/adr/*.md
```

找到下一个编号 `NNNN`（看最大编号 + 1）。

## Step 2: 用模板创建文件

```bash
# 创建
touch docs/architecture/adr/NNNN-<短标题>.md
```

短标题用 kebab-case：`use-redis-cache`、`event-driven-architecture`。

## Step 3: 填写模板

```markdown
# ADR-NNNN: <简明决策标题>

**状态**: 🟡 Proposed / ✅ Accepted / ❌ Deprecated / 🔄 Superseded by ADR-MMMM
**日期**: YYYY-MM-DD
**决策人**: @name1, @name2

## 1. 背景 (Context)

什么促使做这个决策？要解决什么问题？
- 现状是什么？
- 痛点是什么？
- 约束是什么？

## 2. 决策 (Decision)

我们决定...

## 3. 备选方案 (Alternatives Considered)

### 方案 A: ...
- ✅ 优点: ...
- ❌ 缺点: ...

### 方案 B: ... ✅ 已选
- ✅ 优点: ...
- ❌ 缺点: ...

### 方案 C: ...
- ✅ 优点: ...
- ❌ 缺点: ...

## 4. 影响 (Consequences)

### 正面
- ...

### 负面
- ...

### 风险
- ...

## 5. 后果 (Compliance)

✅ **必须**: ...
✅ **必须**: ...
❌ **禁止**: ...

## 6. 验证 (Validation)

如何确认这个决策是对的？
- [ ] 指标 1: ...
- [ ] 指标 2: ...
```

## Step 4: 决策矩阵（必填）

对于有 ≥2 个备选方案的决策，必须填写决策矩阵：

```markdown
## 决策矩阵

| 维度 (权重) | 方案 A | 方案 B | 方案 C |
|------------|--------|--------|--------|
| 性能 (30%) | 7/10 | 9/10 | 6/10 |
| 复杂度 (25%) | 5/10 | 7/10 | 8/10 |
| 团队熟悉度 (20%) | 9/10 | 6/10 | 3/10 |
| 维护成本 (15%) | 6/10 | 8/10 | 7/10 |
| 生态 (10%) | 8/10 | 9/10 | 5/10 |
| **加权总分** | **6.85** | **7.85** | **5.85** |

→ 选 B
```

## Step 5: 状态流转

```
Proposed (草案)
    ↓ 评审通过
Accepted (生效)
    ↓ 决策变更
Deprecated (废弃) 或 Superseded by ADR-MMMM (被替代)
```

## Step 6: 评审流程

| 决策类型 | 需要 Approver |
|----------|---------------|
| 选型（数据库 / 框架） | EM + Tech Lead + SRE Lead（3 个） |
| 模式变更 | EM + Tech Lead（2 个） |
| 引入依赖 | Tech Lead（1 个） |
| 小重构 | Tech Lead（1 个） |

## Step 7: 合并到 main

- PR 标题: `[ADR-NNNN] <title>`
- 必须关联到具体用户故事 / 工单
- Reviewer 写明同意理由
- 合并后通知 `#user-service-dev`

## Step 8: 更新概览文件

在 `docs/architecture/adr/README.md`（如果存在）中追加：

```markdown
| ADR | 标题 | 状态 | 日期 |
|-----|------|------|------|
| [0001](0001-why-postgresql.md) | 为什么选 PostgreSQL | ✅ | 2025-08-20 |
| [0002](0002-why-event-driven.md) | 事件驱动架构 | ✅ | 2025-09-01 |
| [NNNN](NNNN-...md) | <新 ADR> | 🟡 | YYYY-MM-DD |
```

## 反模式

❌ **不要**：
- 不写决策矩阵就选方案
- 没有备选就直接决策
- Accepted 后偷偷修改（违反 ADR 不可变性）
- 把 ADR 当博客写（应聚焦决策）

✅ **应该**：
- 一旦 Accepted，**不修改原文**（除非废弃）
- 变更时新建 ADR 并 `Superseded by`
- 每个 ADR 关联实际工单
- 重要决策必须 ≥ 2 个 Approver

## 与现有 ADR 的关系

读取现有 ADR，避免冲突：

- 选 PostgreSQL 之前必须读 ADR-0001
- 选 Redis 之前必须读 ADR-0002（如果存在）
- JWT 相关决策看 ADR-0003
- 权限缓存看 ADR-0005

新 ADR 应在 `## 影响` 段引用相关旧 ADR。
