# Contributing Guide

> 如何为 Claude Code 企业模板做贡献

---

## 提交流程

```
1. Fork 仓库
2. 创建 feature 分支（git checkout -b feature/xxx）
3. 提交（commit 信息见下文）
4. Push（git push origin feature/xxx）
5. 创建 Pull Request
6. 通过 CI 检查
7. 至少 1 个 Approver
8. Squash merge
```

## 提交信息规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>(<scope>): <description>

<body>

<footer>
```

### Type（必填）

| 类型 | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档变更 |
| `refactor` | 重构（无功能变化）|
| `test` | 测试相关 |
| `perf` | 性能优化 |
| `chore` | 杂项（依赖、配置等）|
| `ci` | CI/CD 变更 |

### Scope（可选）

影响的范围：
- `hooks` — `.claude/hooks/`
- `agents` — `.claude/agents/`
- `skills` — `.claude/skills/`
- `commands` — `.claude/commands/`
- `docs` — `docs/`
- `scripts` — `scripts/`

### 示例

```bash
feat(hooks): add Windows PowerShell hook support

Adds .ps1 versions of all hooks for Windows users:
- secret-scanner.ps1
- bash-policy.ps1 (only Linux/macOS)
- audit-log.ps1
- auto-format.ps1
- pre-plan-check.ps1
- post-task-update.ps1
- doc-sync-check.ps1
- notify-slack.ps1

Closes #123

🤖 Generated with [Claude Code](https://claude.com)
```

## PR Checklist

提交 PR 前请确认：

- [ ] 描述清楚改了什么 + 为什么
- [ ] 关联相关 Issue
- [ ] CI 全部通过（lint + test + secret 扫描）
- [ ] 至少 1 个 Approver
- [ ] CHANGELOG.md 更新
- [ ] 不破坏现有 hook 行为
- [ ] 跨平台测试（Linux + Windows 如果改 hook）
- [ ] 文档同步（如改 API / 配置）

## 开发流程

### 1. 修改前

- 读现有代码风格
- 读 `CLAUDE.md` 的工作流程
- 看 `.planning/current/` 是否有相关任务

### 2. 修改中

- 遵循现有命名
- 加单元测试（如适用）
- 不引入新依赖（除非必要 + ADR 批准）

### 3. 修改后

```bash
# 测试
make test

# 校验 OpenAPI（如果改了 docs/api/）
python -c "import yaml; from openapi_spec_validator import validate; validate(yaml.safe_load(open('docs/api/openapi.yaml')))"

# 检查密钥泄漏
grep -rE "AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}" --include="*.md" --include="*.sh" .

# Shell 脚本语法
for f in $(find .claude/hooks -name "*.sh"); do bash -n "$f"; done
```

## 添加新组件

### 新增 Agent

1. 创建 `.claude/agents/<name>.md`
2. YAML frontmatter 必填：
   ```yaml
   ---
   name: your-agent-name
   description: 一句话描述（Claude 用此判断何时调用）
   tools: Read, Grep, Glob  # 限制工具
   model: sonnet  # 或 opus / haiku
   ---
   ```
3. Body 用 markdown，描述角色和输出格式

### 新增 Skill

1. 创建 `.claude/skills/<skill-name>/SKILL.md`
2. YAML frontmatter 必填 `name` + `description`
3. Body 用 markdown，描述触发条件和步骤

### 新增 Command

1. 创建 `.claude/commands/<command>.md`
2. YAML frontmatter 必填 `description`
3. Body 用 markdown，描述流程

### 新增 Hook

1. 创建 `.claude/hooks/<name>.sh`（Linux/macOS）
2. 创建 `.claude/hooks/<name>.ps1`（Windows）
3. 在 `.claude/settings.json` 的 hooks 中注册
4. 加测试（如适用）

## Code Style

### Markdown

- 一级标题 `#` 仅用于文件名
- 二级标题 `##` 用于章节
- 代码块用 ` ``` ` 包围
- 行宽 ≤ 100 字符（参考 `.editorconfig`）

### Shell

```bash
# 顶部严格模式
set -euo pipefail

# 变量大写
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 函数小写
function log_message() {
    local msg="$1"
    echo "[$(date -Iseconds)] $msg"
}
```

### Python

```python
# Type hints
def get_user(user_id: UUID) -> User:
    """简短描述"""
    ...

# Docstring
def calculate_permissions(user_id: UUID) -> set[str]:
    """
    计算用户的有效权限（含继承）。
    
    Args:
        user_id: 用户 ID
    
    Returns:
        权限字符串集合
    """
```

### JSON / YAML

- 2 空格缩进
- 引号用双引号
- 数组末尾不加逗号

## 测试

```bash
# 跑所有测试
make test

# 跑单个
pytest tests/test_user.py::test_create_user -v

# 覆盖率
make coverage
```

## 发布

只有 maintainer 可以发布：

```bash
# 创建 tag + 自动 release
./release.sh v1.1.0

# CI 会自动：
# 1. 跑测试
# 2. 打包 ZIP + TAR.GZ
# 3. 创建 GitHub Release
# 4. 上传分发包
```

## 联系方式

- **Slack**: `#claude-template-feedback`
- **Issue Tracker**: GitHub Issues
- **Email**: devx-team@company.com
- **Maintainers**: @devex-team

## 行为准则

参见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)（待添加）。

## 许可

贡献即同意本仓库的 [LICENSE](LICENSE)。
