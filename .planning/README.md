# .planning/ - 任务规划系统

> Claude Code 在本项目的"工作记忆"。所有任务从规划开始，到归档结束。

---

## 目录结构

```
.planning/
├── README.md              # 本文件（系统说明）
├── current/               # 当前进行中的任务
│   ├── task_plan.md       # ⭐ 任务主计划（真理源）
│   ├── notes.md           # 调研笔记（append-only）
│   └── progress.md        # 进度 + 复盘
└── archive/               # 已完成的任务（按日期归档）
    └── 2026-06-21-user-login-refactor/
        ├── task_plan.md
        ├── notes.md
        └── progress.md
```

## 5 步标准流程

```
1. 启动      → 创建 .planning/current/task_plan.md
                明确目标 + 验收标准
                       ↓
2. 拆解      → 把任务拆成 2-5 分钟可执行的 subtasks
                每个 subtask 都有完成标准
                       ↓
3. 执行      → 每完成一个 subtask：
                - 更新 task_plan.md 复选框
                - 追加关键发现到 notes.md
                - 进度变化写到 progress.md
                       ↓
4. 验证      → 跑测试 + 部署 staging + 冒烟
                验证通过才能标 "完成"
                       ↓
5. 复盘      → 写 progress.md 的 "经验教训" 段
                整目录移到 archive/
```

## 关键原则

| 原则 | 说明 |
|------|------|
| **小步快走** | 每个 subtask ≤ 30 分钟 |
| **可独立验证** | 每个 subtask 有明确 "完成标准" |
| **失败痕迹保留** | 失败的尝试也要写进 notes.md |
| **append-only** | 不删除历史，只追加 |
| **主真理源** | 任何时候 task_plan.md 是最新状态 |

## 文件格式

### task_plan.md（必填）

```markdown
# Task: <简短描述>

## 目标
<一句话说明要达成什么>

## 验收标准
- [ ] AC-1: <具体可验证>
- [ ] AC-2: ...

## 子任务（Subtasks）
- [ ] 1. <第一步>
- [ ] 2. <第二步>
...

## 决策记录
- 选择 X 而不是 Y，因为...

## 风险
- <潜在问题 + 缓解方案>

## 回滚方案
<如果出问题怎么回滚>
```

### notes.md（追加式）

```markdown
# 调研笔记: <任务名>

## 现状分析
<发现的事实 + 数据>

## 调研结论
- 关键发现 1
- 关键发现 2

## 失败的尝试（保留痕迹）
- ❌ 试过 A 方案，原因是...
- ❌ 试过 B 方案，原因是...

## 参考资料
- 链接 1
- 链接 2
```

### progress.md（每日 + 复盘）

```markdown
# 进度: <任务名>

## 当前状态
🟡 进行中 / 🟢 已完成 / 🔴 阻塞

## 时间线
- YYYY-MM-DD HH:MM: <发生什么>

## 完成度
- [x] AC-1
- [x] AC-2
- [ ] AC-3

## 阻塞 / 风险
- <当前阻塞>

## 经验教训（完成后填）
- ✅ 做得好的
- ❌ 可以更好的
```

## 与 Claude 的协作

Claude 接到任务时：

```
1. 读 task_plan.md 看当前任务
2. 读 notes.md 看已有调研
3. 读 progress.md 看当前进度
4. 继续执行下一个 subtask
5. 每完成一个，更新三个文件
```

## 归档时机

满足以下**全部**条件：

- [ ] 所有 AC 勾选
- [ ] PR merged 或部署完成
- [ ] progress.md 经验教训已写
- [ ] 相关文档已更新（ADR / API docs）

归档命令：
```bash
mv .planning/current .planning/archive/$(date +%Y-%m-%d)-$(basename $(cat .planning/current/task_plan.md | head -1 | awk '{print $2}'))
```

## 与 OpenClaw 的关系

如果主人使用 OpenClaw + claw-plan 系统：
- `.planning/` 对应 claw-plan 的 `planning/current/`
- 格式兼容（task_plan.md / notes.md / progress.md）
- 可以双向同步
