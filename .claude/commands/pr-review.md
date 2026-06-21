---
description: Review the current pull request following company standards
---

# /pr-review

Review the current pull request using company PR checklist.

## Workflow

1. **Identify the PR**:
   ```bash
   PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null)
   if [ -z "$PR_NUMBER" ]; then
     echo "❌ No PR found for current branch"
     exit 1
   fi
   ```

2. **Get PR metadata**:
   ```bash
   gh pr view $PR_NUMBER --json title,body,author,baseRefName,files,additions,deletions
   ```

3. **Run all sub-agents in parallel**:
   - **security-reviewer** — security/OWASP review of diff
   - **api-designer** — API design compliance (if changes touch src/api/)
   - **test-engineer** — test coverage check (if test files changed)
   - **db-migrator** — migration review (if migrations/ changed)

4. **Manual checklist** (PR template items):

   ### 通用
   - [ ] PR 标题格式：`[PROJ-XXXX] <type>: <description>`
   - [ ] 关联 Jira 工单
   - [ ] 描述清晰：改了什么 / 为什么 / 怎么测
   - [ ] 没有 WIP / TODO 注释遗留
   - [ ] 没有 console.log / print 调试代码
   - [ ] 没有 merge conflict

   ### 代码质量
   - [ ] 遵循 PEP 8 + 公司 style guide
   - [ ] 函数 < 50 行
   - [ ] 类 < 300 行
   - [ ] 嵌套 < 4 层
   - [ ] 无重复代码（DRY）
   - [ ] 无 magic number（提取常量）

   ### 测试
   - [ ] 新功能有单元测试
   - [ ] 关键路径有集成测试
   - [ ] 覆盖率不下降
   - [ ] 测试在 CI 通过

   ### 安全
   - [ ] 无 hardcoded secret
   - [ ] SQL 参数化
   - [ ] PII 不进日志
   - [ ] 权限检查完整

   ### 数据库（如果改了 migration）
   - [ ] 迁移有 upgrade + downgrade
   - [ ] 索引用 CONCURRENTLY
   - [ ] NOT NULL 列分步加
   - [ ] 已通知依赖此表的服务

   ### 文档
   - [ ] CLAUDE.md 已更新（如有架构变更）
   - [ ] docs/api.md 已更新（如改了 API）
   - [ ] CHANGELOG.md 已更新（如发版）

5. **Output review report**:

   ```markdown
   ## PR Review: #$PR_NUMBER - $TITLE

   **作者**: @author
   **目标分支**: main
   **变更**: +X / -Y 行

   ### 🤖 Sub-Agent Reports

   #### Security Reviewer
   - 🚨 Critical: [数量]
   - ⚠️ Warnings: [数量]
   - ✅ Verified Safe: [数量]

   #### API Designer
   - ...

   #### Test Engineer
   - Coverage: X% → Y%
   - Tests added: N
   - ...

   #### DB Migrator (if applicable)
   - Migration risk: 🟢/🟡/🔴
   - ...

   ### 📋 Manual Checklist
   - [x] 标题格式正确
   - [x] 关联 Jira
   - [ ] 测试覆盖率不足（68% < 80%）
   ...

   ### ✅ Ready to Merge?
   - 🟢 YES — 所有 critical 通过
   - 🟡 WITH CHANGES — 需要小修
   - 🔴 BLOCKED — 有 critical issue

   ### Required Follow-ups
   - [ ] Comment 1: ...
   - [ ] Comment 2: ...

   ### 💬 Review Comments to Post
   ```
   [自动生成的具体评论]
   ```
   ```

6. **Post review comments** (with user approval):
   ```bash
   gh pr review $PR_NUMBER --comment --body "..."
   # 或
   gh pr review $PR_NUMBER --request-changes --body "..."
   # 或
   gh pr review $PR_NUMBER --approve --body "..."
   ```

## Approval Rules

| 状态 | 行为 |
|------|------|
| 0 critical + 0 warning | 建议 Approve |
| 1-3 warning | 建议 Request Changes（需修） |
| 1+ critical | 必须 Request Changes（不可 Approve） |
| > 5 warning | 强烈建议拆分 PR |

## Important Constraints

- **不修改代码**：只审查 + 评论
- **礼貌专业**：评论聚焦问题，不指责个人
- **可执行**：每条评论要有具体修复建议
- **明确决策**：给出 Approve / Request Changes / Comment 之一
