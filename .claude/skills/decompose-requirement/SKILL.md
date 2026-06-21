---
name: decompose-requirement
description: 把模糊的需求拆解成可执行的子任务清单，写入 .planning/current/task_plan.md
---

# Decompose Requirement

把收到的需求（通常来自用户故事 / PROJ 工单 / Slack）拆成 2-5 分钟可执行的 subtasks。

## 触发时机

- 用户说"开始任务 PROJ-XXXX"
- 用户描述新功能需求
- 用户要求"拆解这个需求"
- Claude 自动识别任务边界时

## Step 1: 澄清需求（Socratic 5 问）

**任何模糊需求必须先问清楚再拆**：

1. **给谁用？** → 用户角色（员工 / HR / Admin / 系统）
2. **解决什么问题？** → 痛点 + 价值
3. **成功标准是什么？** → 可量化的验收
4. **不做什么？** → 明确边界
5. **依赖 / 约束？** → 时间 / 资源 / 上下游

如果回答不清楚，**返回给用户问**，不要猜。

## Step 2: 读现有上下文

在拆解前必须读：

- `docs/requirements/business-rules.md` — 关联业务规则编号 BR-NNN
- `docs/domain/glossary.md` — 业务术语统一
- `docs/architecture/adr/` — 架构约束
- `docs/project/sprint-backlog.md` — 当前 sprint 上下文
- 关联用户故事（`docs/requirements/user-stories/PROJ-XXXX.md`）

## Step 3: 拆解成 Subtasks

每个 subtask 必须满足：

| 原则 | 说明 |
|------|------|
| **2-5 分钟可完成** | 超过 30 分钟的必须再拆 |
| **可独立验证** | 每个 subtask 有明确"完成标准" |
| **顺序合理** | 标注依赖关系 |
| **范围明确** | 不做不相关的事 |

## Step 4: 排序

```
DAG（有向无环图）:

[调研现状] → [设计方案] → [写 ADR]
                                ↓
                           [实施]
                                ↓
                      [测试] → [部署 staging] → [验证] → [归档]
```

## Step 5: 风险评估

每个 subtask 标 🟢/🟡/🔴：
- 🟢 已知做法
- 🟡 需要探索
- 🔴 有不确定性

## Step 6: 写到 .planning/current/task_plan.md

**模板**：

```markdown
# Task: <需求简述> [PROJ-XXXX]

## 目标
<一句话>

## 验收标准
- [ ] AC-1: Given/When/Then
- [ ] AC-2: ...

## 子任务

### 阶段 1: 调研 (预计 30min)
- [ ] 1.1 读关联文档 (10min)
  - 完成标准: 已列 BR-NNN 关联
- [ ] 1.2 profile 现状（如需） (20min)
  - 完成标准: profile 数据已贴 notes.md

### 阶段 2: 设计 (预计 1h)
- [ ] 2.1 写 ADR 草案 (30min) 🟡
  - 完成标准: docs/architecture/adr/NNNN-...md 已创建
- [ ] 2.2 列出备选方案 (20min)
  - 完成标准: ≥ 2 个备选 + 取舍
- [ ] 2.3 评审通过 (10min)
  - 完成标准: 2 个 Approve

### 阶段 3: 实施 (预计 Xh)
- [ ] 3.1 ... 
- [ ] 3.2 ...

### 阶段 4: 验证 (预计 30min)
- [ ] 4.1 单元测试 + 集成测试通过
- [ ] 4.2 部署 staging + 冒烟
- [ ] 4.3 PM 验收

## 决策记录
- 选择 X: 因为...

## 风险
- 🟡 风险 A → 缓解: ...

## 回滚方案
git revert HEAD && redeploy

## 关联
- 用户故事: ...
- ADR: ...
- 工单: ...
```

## Step 7: 同步给用户

输出摘要：

```markdown
✅ 已拆解 PROJ-XXXX 到 .planning/current/task_plan.md

- **目标**: ...
- **Subtasks**: N 个（预计总 Xh）
- **关键风险**: ...
- **下一步**: 1.1 读关联文档

是否开始执行？
```

## 反模式 (Anti-patterns)

❌ **不要**：
- 一次性写 20 个 subtasks（应分阶段）
- 写"实现功能 X"这种模糊 subtask（应写"加 GET /v1/X 端点 + 单元测试"）
- 跳过调研直接实施
- 不写验收标准

✅ **应该**：
- 每个 subtask 有 Owner（即使是自己）
- 每个 subtask 有时间预估
- 风险评估清晰
- 保留调整空间

## 与其他 skill 的协作

- `plan-execution` — 在分解后生成执行路径
- `create-adr` — 设计阶段的 ADR 自动写
- `update-progress` — 执行时自动更新进度
