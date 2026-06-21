---
description: 把当前需求或指定任务拆解成 2-5 分钟可执行的子任务
---

# /decompose [需求或 task_plan.md]

把模糊需求拆成可执行 subtasks。

## 工作流

### 1. 读取上下文

```bash
# 如果用户给了 task_plan.md 路径
cat $ARGUMENTS  # 该文件

# 否则读 .planning/current/task_plan.md
cat .planning/current/task_plan.md 2>/dev/null
```

### 2. 调用 decompose-requirement skill

按照 SKILL.md 的 7 步执行：
1. Socratic 5 问
2. 读上下文
3. 拆 subtasks
4. 排序 + DAG
5. 风险评估
6. 写入 task_plan.md
7. 同步给用户

### 3. 输出摘要

```markdown
✅ 已拆解

**目标**: <一句话>
**Subtasks**: N 个
**关键路径**: Xh
**里程碑**: 4 个（M1 调研 / M2 设计 / M3 实施 / M4 部署）
**关键风险**: ...

**下一步**: 阶段 1.1 <subtask>

是否开始执行？
```

## 强制规则

| 规则 | 说明 |
|------|------|
| 每个 subtask ≤ 30min | 超了必须再拆 |
| 每个 subtask 有"完成标准" | 不写不算 |
| 风险标 🟢/🟡/🔴 | 没标不算 |
| 写回滚方案 | 没写不算 |

## 输出模板

### 完整输出

```markdown
# 任务拆解: [PROJ-XXXX] <name>

## 目标
<一句话>

## 验收标准
- [ ] AC-1: ...
- [ ] AC-2: ...

## 子任务

### 阶段 1: 调研 (30min)
- [ ] 1.1 <subtask> (10min) 🟢
  - 完成标准: ...
- [ ] 1.2 <subtask> (20min) 🟡
  - 完成标准: ...

### 阶段 2: 设计 (1h)
- [ ] 2.1 <subtask> 🟡
- ...

### 阶段 3: 实施 (Xh)
...

### 阶段 4: 验证 (Xmin)
...

## 决策记录
- 选择 X 而不是 Y: 因为...

## 风险
| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| ... | 🟢/🟡/🔴 | ... | ... |

## 依赖
- 前置: ...
- 阻塞: ...

## 回滚方案
git revert HEAD && redeploy

## 关联
- 用户故事: ...
- ADR: ...
```

## 反模式

❌ **不要**：
- "实现 X 功能" 这种模糊 subtask
- 不写完成标准
- 不评估风险
- 跳过 Socratic 5 问

✅ **应该**：
- 具体到能立即动手
- 风险量化
- 留 checkpoint
