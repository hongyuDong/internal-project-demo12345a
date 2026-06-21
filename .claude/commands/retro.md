---
description: 复盘当前任务或最近完成的任务
---

# /retro [可选: 任务 ID]

复盘任务，写入 .planning/current/progress.md 的"经验教训"段。

## 工作流

### 1. 读取任务信息

```bash
cat .planning/current/task_plan.md
cat .planning/current/progress.md
cat .planning/current/notes.md
```

### 2. 分析数据

| 维度 | 数据来源 |
|------|----------|
| **实际工时** | notes.md 时间戳 / git log |
| **完成度** | task_plan.md 复选框 |
| **AC 覆盖** | task_plan.md AC + 测试报告 |
| **风险命中** | progress.md 时间线 |
| **失败的尝试** | notes.md "失败的尝试"段 |
| **沟通问题** | progress.md "沟通"段 |

### 3. 输出复盘报告

```markdown
## 🔄 复盘: [PROJ-XXXX] <name>

### 基本数据
- **开始**: YYYY-MM-DD HH:MM
- **结束**: YYYY-MM-DD HH:MM
- **持续**: Xh
- **预估**: Yh
- **偏差**: ±Z%
- **PR**: #N
- **部署**: staging ✅ / prod ✅

### 完成度
- AC: N/M (X%)
- Subtasks: A/B
- 测试覆盖率: X%

### ✅ 做得好的

1. **<具体行为>**
   - **数据**: ...
   - **原因**: ...

2. ...

### ❌ 可以更好的

1. **<具体行为>**
   - **数据**: ...
   - **影响**: ...
   - **下次怎么做**: ...

2. ...

### 💡 学到的教训

1. **<洞察>**
   - **场景**: ...
   - **结论**: ...

2. ...

### 📋 行动项

| # | 描述 | Owner | Due |
|---|------|-------|-----|
| 1 | ... | @name | YYYY-MM-DD |
| 2 | ... | @name | YYYY-MM-DD |

### 团队分享

**值得告诉团队的**:
- ...

**下次 sprint 应该避免的**:
- ...
```

### 4. 写入 progress.md

把"经验教训"段追加到 `.planning/current/progress.md`：

```markdown
## 经验教训（完成后填）

### ✅ 做得好的
- ...

### ❌ 可以更好的
- ...

### 💡 下次改进
- ...
```

### 5. 通知团队

如果学到的东西值得分享，建议发到 Slack：
```markdown
📚 <PROJ-XXXX> 复盘分享

**关键学习**:
1. ...
2. ...

**完整复盘**: docs/planning/archive/YYYY-MM-DD-.../progress.md
```

## 选项

```bash
/retro                    # 当前任务
/retro PROJ-1001          # 指定任务
/retro --template-only    # 只输出模板
/retro --team             # 输出团队分享版
```

## 复盘时机

| 类型 | 时机 |
|------|------|
| **任务级** | 每个 PROJ 完成后 |
| **Sprint 级** | Sprint 结束 |
| **事故级** | P0/P1 事故后 24h 内 |
| **季度级** | 季度 review |

## 反模式

❌ **不要**：
- 走过场（"做得很好，继续保持"）
- 只批评不表扬
- 不写行动项
- 不分享（团队无法学习）

✅ **应该**：
- 数据驱动
- 行为可观察（不是"团队不够努力"）
- 行动项有 Owner + Due
- 公开分享（团队知识资产）
