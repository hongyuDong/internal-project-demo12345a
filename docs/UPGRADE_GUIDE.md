# 升级指南

> 从旧版本升级到当前版本的步骤

**当前版本**: v1.0.3  
**支持升级路径**: v1.0.x → v1.0.3

---

## 📋 版本兼容性矩阵

| 从 | 到 | 兼容性 | 升级难度 |
|----|----|--------|----------|
| v1.0.0 | v1.0.3 | ✅ 完全兼容 | 🟢 简单（pull + 重启） |
| v1.0.1 | v1.0.3 | ✅ 完全兼容 | 🟢 简单 |
| v1.0.2 | v1.0.3 | ✅ 完全兼容 | 🟢 简单 |
| v1.0.3 | 未来 v1.1 | ✅ 向后兼容 | 🟡 中等 |
| v1.x | v2.0 | ⚠️ 可能有破坏 | 🔴 复杂 |

---

## 🚀 v1.0.x → v1.0.3 升级

### Step 1: 备份

```bash
# 备份你的项目
cd your-project
cp -r .claude .claude.bak
cp CLAUDE.md CLAUDE.md.bak
```

### Step 2: 查看变更

```bash
# 看新版本有什么变化
cat CHANGELOG.md
```

### Step 3: 升级选项

#### 选项 A: 完全替换（推荐新项目）

```bash
# 重新运行 install.bat
# Windows:
install.bat
# 选择模式 1（项目级安装）
# 当提示"已存在 .claude/ 是否覆盖"时，选择 Y

# macOS/Linux:
./install.sh
```

#### 选项 B: 增量升级（保留定制）

```bash
# 1. 下载新版本 zip
#    https://github.com/company/claude-code-template/releases

# 2. 解压到临时目录
unzip internal-project.zip -d /tmp/new-version/

# 3. 逐文件复制（不要覆盖你修改过的）
cp /tmp/new-version/.claude/hooks/secret-scanner.* .claude/hooks/
cp /tmp/new-version/.claude/hooks/pre-plan-check.* .claude/hooks/
cp /tmp/new-version/.claude/hooks/post-task-update.* .claude/hooks/
# ... 其他

# 4. 合并 settings.json（手动 diff）
diff /tmp/new-version/.claude/settings.json .claude/settings.json
```

#### 选项 C: Git 方式（推荐有 Git 仓库的项目）

```bash
# 假设你的项目已经 fork 了 claude-code-template

# 添加官方仓库作为 remote
git remote add upstream https://github.com/company/claude-code-template.git

# 拉取最新
git fetch upstream

# 合并到你的分支
git merge upstream/main --no-ff

# 解决冲突（如有）
# 通常 settings.json + CLAUDE.md + hooks 会有冲突
# 保留你的定制 + 应用新功能
```

### Step 4: 验证

```bash
# 1. 检查所有文件到位
ls .claude/hooks/         # 应该有 .sh 和 .ps1
ls .claude/agents/         # 应该有 8 个
ls .claude/skills/         # 应该有 7 个

# 2. 验证 hooks 语法
for f in .claude/hooks/*.sh; do
    bash -n "$f" && echo "OK: $f" || echo "FAIL: $f"
done

# 3. 验证 settings.json
python3 -c "import json; json.load(open('.claude/settings.json')); print('OK')"

# 4. 验证 OpenAPI（如果改过 docs/api/）
python3 -c "
import yaml
from openapi_spec_validator import validate
from openapi_spec_validator.readers import read_from_filename
spec_dict, _ = read_from_filename('docs/api/openapi.yaml')
validate(spec_dict)
print('OK')
"
```

### Step 5: 测试

```bash
# 跑项目
make dev
# 或
uvicorn src.main:app --reload

# 检查
curl http://localhost:8000/healthz
# 期望: {"status":"ok"}

# 跑测试
pytest tests/ -v
```

### Step 6: 提交

```bash
git add .
git commit -m "chore: upgrade claude-code-template to v1.0.3

- New: 4 PowerShell hooks
- New: SECURITY.md + LICENSE + CONTRIBUTING.md
- New: 代码骨架 (src/)
- Update: CLAUDE.md 弱化强制
- Update: settings.json 加注释

详见 CHANGELOG.md"

git push origin main
```

---

## ⚠️ v1.0.3 的破坏性变更

| 变更 | 影响 | 迁移 |
|------|------|------|
| CLAUDE.md 工作流程分级 | 🟡 软 | 不需要操作，新版兼容旧用法 |
| settings.json 加 `_about` 字段 | 🟢 无 | Claude 忽略未知字段 |
| 删除 `run-debug.bat` | 🟢 无 | 功能被 init-git.bat 替代 |
| 新增 `.planning/.cache/` 目录 | 🟢 无 | .gitignore 已排除 |
| .gitattributes 行尾规则 | 🟡 可能 | 见下方 |

### Windows 用户注意事项

如果你之前在 Windows 上跑过 hooks：
- 之前：`.sh` 不能直接跑（要 WSL/Git Bash）
- 现在：可以用 `.ps1` 版本（PowerShell Core）

**首次启用 PowerShell hooks**：
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## 🆘 升级失败回滚

### 如果升级后 Claude Code 行为异常

```bash
# 1. 恢复备份
cp -r .claude.bak/* .claude/
cp CLAUDE.md.bak CLAUDE.md

# 2. 重启 Claude Code
# Ctrl+C → claude

# 3. 如果 hooks 报错
chmod +x .claude/hooks/*.sh

# 4. 如果 settings.json 损坏
# 从 .claude.bak 恢复
```

### 如果单个文件有问题

```bash
# 查看 diff
git diff HEAD~1 -- .claude/hooks/secret-scanner.sh

# 恢复单个文件
git checkout HEAD~1 -- .claude/hooks/secret-scanner.sh
```

---

## 📦 从非模板项目升级

如果你的项目之前没用过这个模板，但想引入：

### 评估（30 分钟）

- 读 [README.md](../README.md)
- 看 [docs/api/openapi.yaml](../api/openapi.yaml)（如适用）
- 看 [CLAUDE.md](../CLAUDE.md) 工作流程

### 集成（2-4 小时）

```bash
# 1. 把 .claude/ 复制到项目
cp -r /path/to/internal-project/.claude your-project/

# 2. 把 CLAUDE.md 复制（改名避免冲突）
cp /path/to/internal-project/CLAUDE.md your-project/

# 3. 编辑 CLAUDE.md
# - 替换项目名 / 技术栈
# - 删除不适用的部分

# 4. 编辑 docs/
# - 替换业务规则
# - 删除不适用的文档

# 5. 提交
git add .
git commit -m "feat: integrate claude-code-template v1.0.3"
```

### 试运行（1-2 天）

- 跑 1-2 个 sprint
- 收集反馈
- 决定是否继续

---

## 🔄 升级到未来版本

### Minor 版本升级（v1.x → v1.y）

```
- 自动向后兼容
- 看 CHANGELOG 了解新功能
- 拉取即可
```

### Major 版本升级（v1.x → v2.0）

```
- 可能有破坏性变更
- 必有 UPGRADE_GUIDE
- 评估影响（建议 1 周）
- 试点 → 正式升级
```

---

## ❓ FAQ

### Q: 升级会破坏我的自定义吗？

A: 取决于升级方式：
- 选项 A（完全替换）：会，备份后再装
- 选项 B（增量）：不会，只加新文件
- 选项 C（Git merge）：可能冲突，保留你的修改

### Q: 我修改了 hooks 怎么办？

A: hooks 在 `.claude/hooks/`，你的修改会被覆盖。建议：
- 把你的修改提交到 fork 仓库
- 升级前先 PR 到主仓库
- 或用选项 B 增量升级（保留你的修改）

### Q: 升级需要停止服务吗？

A: 不需要。`.claude/` 是开发工具，不影响生产服务。
唯一影响：开发体验中断（几分钟到几小时）。

### Q: 多人项目怎么协调升级？

A: 
1. Tech Lead 先在测试项目验证
2. 发 RFC 给团队（带 UPGRADE_GUIDE 链接）
3. 安排升级窗口（通常周末）
4. 升级后集体 review

### Q: 升级失败影响生产吗？

A: 不影响。Claude Code 配置只在开发时用。
生产服务跑的是 Docker 镜像，不依赖 `.claude/`。

---

## 📞 升级遇到问题

1. **查文档**：[CONTRIBUTING.md](../CONTRIBUTING.md) + 本文档
2. **查 issues**：https://github.com/company/claude-code-template/issues
3. **问团队**：Slack `#claude-template-feedback`
4. **紧急**：Slack `#claude-template-oncall`

---

**当前版本**: v1.0.3  
**下次升级**: 关注 GitHub Releases
