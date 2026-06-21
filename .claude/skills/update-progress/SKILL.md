---
name: update-progress
description: 每个 subtask 完成后自动更新 .planning/current/ 三个文件 + 必要时通知用户
---

# Update Progress

**触发**: 每完成一个 subtask / 状态变化 / 阻塞发生

## Step 1: 更新 task_plan.md

把完成的 subtask 复选框打勾：

```diff
- [ ] 1.1 读文档
+ [x] 1.1 读文档
```

## Step 2: 追加 notes.md

如有新发现：

```markdown
### YYYY-MM-DD HH:MM — <subtask 名>

- **做了什么**: ...
- **结果**: ...
- **关键发现**: ...
- **影响**: ...
```

## Step 3: 更新 progress.md

```markdown
## 总体进度

- 之前: ████░░░░░░░░░░░░ 25%
- 现在: ██████░░░░░░░░░░ 35%

## 时间线

| YYYY-MM-DD HH:MM | 完成 1.1 读文档 |
```

## Step 4: 计算新进度

```
完成度 = 已完成 subtasks / 总 subtasks × 100%
```

## Step 5: 判断是否通知用户

| 触发 | 通知？ | 方式 |
|------|--------|------|
| 完成 subtask | ❌ | 下次报告 |
| 完成 milestone | ✅ | Slack / 报告 |
| 状态变化（绿/黄/红） | ✅ | 立刻 |
| 阻塞发生 | ✅ | 立刻 + 解阻塞建议 |
| 风险变高 | ✅ | 警告 |
| 进度落后计划 > 20% | ✅ | 警告 |

## Step 6: 通知模板

### Milestone 完成

```markdown
🎉 **M1 完成**: 调研完成

- ✅ 1.1 读文档
- ✅ 1.2 profile 现状
- 📝 notes.md 有 7 条新发现
- 🟢 状态: 健康

下一步: M2 设计阶段
是否继续？
```

### 阻塞

```markdown
🚨 **阻塞发生**: 3.1 实施卡住

**问题**: ...
**根因**: ...
**已尝试**: ...
**建议方案**: ...

是否需要人工介入？
```

### 进度落后

```markdown
⚠️ **进度落后**

- 计划完成: 60%
- 实际完成: 40%
- 落后: 20%

**根因**: ...
**建议**: 缩小范围 / 加人 / 延长 deadline
```

## Step 7: 检查整体健康度

每次更新时检查：

| 检查 | 异常时 |
|------|--------|
| 进度是否落后计划 | ⚠️ 通知 |
| 是否有 subtask 卡 > 30 分钟 | 🚨 阻塞 |
| 风险等级是否升级 | ⚠️ 重新评估 |
| 是否偏离原目标 | 🚨 立刻确认 |

## Step 8: 自动清理

- notes.md 超过 1000 行 → 提示归档
- archive 超过 10 个 → 提示清理老归档
- 当前任务超过 2 周 → 提示用户

## 实现示例

```bash
# 在 hook 里调用
post_task_update() {
  local task_id="$1"
  local subtask_id="$2"
  
  # 1. 更新 task_plan.md
  sed -i "s/- \[ \] $subtask_id/- [x] $subtask_id/" .planning/current/task_plan.md
  
  # 2. 追加 progress.md
  echo "### $(date '+%Y-%m-%d %H:%M') — 完成 $subtask_id" >> .planning/current/progress.md
  
  # 3. 计算进度
  local total=$(grep -c "^- \[" .planning/current/task_plan.md)
  local done=$(grep -c "^- \[x\]" .planning/current/task_plan.md)
  local pct=$((done * 100 / total))
  
  echo "📊 进度: $done/$total ($pct%)"
  
  # 4. 通知（如有变化）
  # ...
}
```

## 与其他 skill 的关系

- 由 `decompose-requirement` 启动后激活
- 每个 subtask 完成时被调用
- 任务完成时配合 `/archive` 命令归档
