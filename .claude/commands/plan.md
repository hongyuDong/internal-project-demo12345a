---
description: 规划新功能或任务，自动调 product-owner / architect / planner 三个 sub-agent
---

# /plan [PROJ-XXXX 或需求描述]

启动新任务规划流程。

## 工作流

### 1. 澄清需求

如果用户没给具体需求，先问：

```markdown
请回答以下 5 个问题（不清晰就不开始）：

1. **这是什么任务？** （PROJ-XXXX 或简述）
2. **为什么做？** （业务痛点 + 价值）
3. **成功标准？** （可量化的验收）
4. **不做什么？** （明确边界）
5. **依赖 / 约束？** （时间 / 资源 / 上下游）
```

### 2. 并行调用三个 sub-agent

```
请并行调用以下 sub-agent：

1. product-owner: 验证需求是否符合 PRD / 业务规则
2. architect: 审查是否需要架构决策（如有，强制写 ADR）
3. planner: 把需求拆解成 2-5 分钟可执行的 subtasks
```

### 3. 等待三个 sub-agent 输出

每个 sub-agent 输出后，合并为最终的：

```markdown
## 任务规划: [PROJ-XXXX] <name>

### 业务审查（来自 product-owner）
- PRD 场景: ...
- 业务规则: BR-NNN
- 验收标准: ✅ N/M 覆盖
- 阻塞问题: ...

### 架构审查（来自 architect）
- 是否需要 ADR: 是 / 否
- 决策推荐: ...
- 影响范围: ...

### 任务拆解（来自 planner）
- 阶段 1: 调研 (Xmin) — N 个 subtasks
- 阶段 2: 设计 (Xmin) — N 个 subtasks
- 阶段 3: 实施 (Xh) — N 个 subtasks
- 阶段 4: 验证 (Xmin) — N 个 subtasks
- **总关键路径**: Xh

### 已写入文件
- ✅ .planning/current/task_plan.md
- ✅ .planning/current/notes.md
- ✅ .planning/current/progress.md
- 🟡 .claude/architecture/adr/NNNN-...md（如需 ADR）

### 下一步
**确认后开始执行**：阶段 1 subtask 1
**等用户指令**：是否开始？
```

### 4. 等待用户确认

**不要自动开始实施**，必须等用户确认。

如果用户说"开始"，调用 `decompose-requirement` skill 启动执行。

## 选项

```bash
/plan PROJ-1001             # 规划具体工单
/plan "实现用户头像上传"     # 规划自然语言需求
/plan --dry-run PROJ-1001   # 只生成不写入文件
/plan --help                # 帮助
```

## 反模式

❌ **不要**：
- 没澄清需求就开始拆解
- 跳过 sub-agent（直接自己写）
- 自动开始实施（必须等用户确认）
- 用模糊语言（"大约"、"可能"）

✅ **应该**：
- 强制走 Socratic 5 问
- 并行调用 sub-agent（节省时间）
- 输出可量化的结果
- 让用户决策
