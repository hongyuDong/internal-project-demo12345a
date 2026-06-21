# 验收标准模板 (Acceptance Criteria)

> 每个用户故事 / 工单都必须有明确的验收标准。  
> 使用 **Given-When-Then** 格式，让 PM / Dev / QA / 用户四方对齐。

---

## 模板

```markdown
# [PROJ-NNNN] <功能简述>

## 背景
- **用户故事**: As a [角色], I want [功能], so that [价值]
- **关联 PRD**: docs/requirements/PRD.md#场景-X
- **关联业务规则**: BR-XXX, BR-YYY

## 验收标准

### AC-1: 正常路径
**Given** [前置条件]
**When** [用户操作]
**Then** [预期结果]

### AC-2: 边界情况
...

### AC-3: 错误处理
...

## 非验收标准（明确不做）
- ❌ 不做 A
- ❌ 不做 B

## 度量
- 性能: P99 < Xms
- 覆盖: 单元测试 ≥ 80%
- 兼容性: 支持 iOS / Android / Web

## Definition of Done
- [ ] 代码实现完成
- [ ] 单元测试 + 集成测试通过
- [ ] 覆盖率达标
- [ ] PR review 通过（≥1 approver）
- [ ] 部署到 staging 并冒烟测试
- [ ] PM 在 staging 验收签字
- [ ] 文档更新（API / Runbook / CHANGELOG）
```

---

## 示例：完整填写

```markdown
# PROJ-1001 用户自助改密码

## 背景
- **用户故事**: As a 员工, I want 在 Web 上自助改密码, so that 不用走工单
- **关联 PRD**: PRD.md#场景-X（待补）
- **关联业务规则**: BR-003 (SSO 强制 → 仅服务账号可改本地密码)

## 验收标准

### AC-1: 正常路径
**Given** 用户已登录 SSO
**When** 进入个人设置 → 修改密码 → 输入旧密码 + 新密码 × 2
**Then** 显示"修改成功"，下次登录用新密码

### AC-2: 旧密码错误
**Given** 用户已登录
**When** 输入错误的旧密码
**Then** 显示"旧密码错误"，不修改

### AC-3: 新密码不符合复杂度
**Given** 用户已登录
**When** 输入的新密码不满足 BR-016（长度 < 16 等）
**Then** 显示具体错误（"密码至少 16 字符"），不提交

### AC-4: 二次输入不一致
**Given** 用户已登录
**When** 两次输入的新密码不一致
**Then** 显示"两次输入不一致"，不提交

### AC-5: 速率限制
**Given** 用户已登录
**When** 5 分钟内尝试 5 次错误旧密码
**Then** 第 6 次显示"操作过于频繁，请 5 分钟后再试"

### AC-6: 审计日志
**Given** 任何密码修改
**When** 操作完成
**Then** 审计日志记录 user_id + IP + 时间 + 结果（成功 / 失败原因）

## 非验收标准
- ❌ 不做密码找回（走 SSO reset 流程）
- ❌ 不做忘记密码（SSO 已覆盖）

## 度量
- 性能: P99 < 200ms
- 覆盖: ≥ 85%

## Definition of Done
- [x] 代码实现完成
- [x] 单元测试 + 集成测试通过
- [x] 覆盖率 92%
- [x] PR review 通过（2 approver）
- [ ] 部署 staging 验收（待 PM）
- [ ] API 文档更新
```

---

## 评审 checklist

PM 在验收前必须确认：

- [ ] 所有正常路径有 AC
- [ ] 至少 2 个边界 AC
- [ ] 至少 1 个错误 AC
- [ ] 性能 / 安全 / 审计 AC 齐全
- [ ] 与业务规则编号一一对应
- [ ] Definition of Done 全部勾选
