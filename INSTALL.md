# install.bat 使用说明

> 双击 `install.bat` 一键把本模板安装到本地 Claude Code。

---

## 4 种安装模式

### 🅰️ 模式 1：项目级安装（推荐）

**场景**：给现有项目添加企业级 Claude Code 配置

**步骤**：
1. 双击 `install.bat`
2. 输入 `1`
3. 输入目标项目路径，如 `D:\projects\my-app`
4. 等待复制完成

**复制内容**：
```
D:\projects\my-app\
├── .claude\               # 完整 Claude Code 配置
├── CLAUDE.md              # 项目记忆
├── docs\internal-project\ # 业务/架构/项目文档（业务级）
│   ├── requirements\
│   ├── domain\
│   ├── architecture\
│   └── project\
├── docs\api\              # OpenAPI 3.1 规范（API 级）
│   ├── openapi.yaml
│   ├── openapi.json
│   ├── README.md
│   └── changelog.md
└── .planning\             # 任务规划系统
```

**特点**：
- ✅ 只影响指定项目
- ✅ 不污染其他项目
- ✅ 卸载简单

---

### 🅱️ 模式 2：全局安装

**场景**：让所有项目都能用本模板的 sub-agents / skills / commands

**步骤**：
1. 双击 `install.bat`
2. 输入 `2`
3. 等待复制完成

**复制到**：`%USERPROFILE%\.claude\`

**特点**：
- ⚠️ 影响所有项目
- ⚠️ `settings.json` 和 `hooks` 不能全局（仍需项目级）

---

### 🅲️ 模式 3：模板项目

**场景**：新建项目时作为起点

**步骤**：
1. 双击 `install.bat`
2. 输入 `3`
3. 输入新项目路径，如 `D:\projects\my-claude-app`
4. 等待复制完成

**复制内容**：整个 `internal-project/` 目录

**特点**：
- ✅ 完整示例项目（FastAPI + PostgreSQL + Kafka）
- ✅ 可以直接当新项目骨架

---

### 🅳️ 模式 4：卸载

**场景**：清理已安装的文件

**两种子模式**：
- 项目级：输入项目路径，删除该项目的 `.claude/` + `CLAUDE.md` + `docs\internal-project\`
- 全局级：删除 `%USERPROFILE%\.claude\` 中本模板安装的内容

**默认会备份**到 `.bak`

---

## 快速卸载

直接双击 `uninstall.bat`（脚本自带）

---

## Windows ↔ WSL 注意事项

| 项目 | 说明 |
|------|------|
| `.sh` hooks | Windows 不能直接执行；如果用 WSL + WSL 里的 Claude Code，可以正常跑 |
| 路径分隔符 | bat 用 `\`；脚本已处理，但建议统一用 `/` |
| 行尾符 | bat 用 CRLF；项目里其他 .md 用 LF；脚本已设 chcp 65001 |
| Git Bash | 推荐在 Git Bash 里跑 bat 脚本，路径更兼容 |

---

## 示例会话

```
C:\Users\you\Downloads\internal-project\install.bat

============================================================
  Claude Code Enterprise Template - One-Click Installer
  internal-user-service  ||  36 files  ||  v1.0
============================================================

[1/5] [INFO] 检测环境...
       [OK] Claude Code 已安装: 1.0.17
       [OK] 模板包含 36 个文件

[2/5] 请选择安装模式:

   [1] 项目级安装 (推荐)
   [2] 全局安装
   [3] 模板项目
   [4] 卸载已安装的
   [5] 查看详细帮助
   [0] 退出

        请选择 [0-5]: 1

[3/5] [INFO] 项目级安装模式

        请输入目标项目绝对路径 (如 D:\projects\my-app): D:\projects\my-app

        [INFO] 复制 .claude/ ...
        [INFO] 复制 CLAUDE.md ...
        [INFO] 复制 docs/ ...
        [INFO] 复制 .planning/ ...

============================================================
  [OK] 项目级安装成功!
============================================================

安装位置: D:\projects\my-app

下一步:
   1. cd /d "D:\projects\my-app"
   2. 编辑 CLAUDE.md (替换项目名/技术栈/规则)
   3. 编辑 docs/requirements/business-rules.md (按需)
   4. claude  启动 Claude Code

============================================================
  完成!
============================================================
请按任意键继续. . .
```

---

## 高级用法

### 静默安装（PowerShell）

```powershell
# 项目级安装
$env:INSTALL_MODE = "1"
$env:INSTALL_TARGET = "D:\projects\my-app"
cmd /c install.bat

# 全局安装
$env:INSTALL_MODE = "2"
cmd /c install.bat
```

### 批量安装多个项目

```batch
@echo off
for %%p in (D:\proj1 D:\proj2 D:\proj3) do (
    echo Installing to %%p ...
    xcopy /E /I /Y /Q ".\.claude" "%%p\.claude\"
    copy /Y ".\CLAUDE.md" "%%p\CLAUDE.md"
)
```

---

## 故障排查

### Q: 双击后闪退？
A: 用 cmd 运行查看错误：`Win+R` → `cmd` → 拖入 bat 文件 → 回车

### Q: 提示"权限不足"？
A: 右键 bat → "以管理员身份运行"

### Q: 中文乱码？
A: 已是 UTF-8 (chcp 65001)。如果还有乱码，Win+R 输入 `intl.cpl` → 管理 → 更改系统区域设置 → 勾选"Beta: Unicode UTF-8"

### Q: 卸载不干净？
A: 手动删除 `.claude\.bak`（已备份的内容）

---

## 文件清单

```
internal-project/
├── install.bat           # 主安装脚本
├── uninstall.bat         # 快速卸载脚本
├── INSTALL.md            # 本说明
├── README.md             # 项目说明
├── CLAUDE.md             # 项目记忆（被安装）
├── .claude/              # 被安装
├── docs/                 # 被安装
└── .planning/            # 被安装
```

---

**版本**: v1.0  
**更新**: 2026-06-21  
**兼容性**: Windows 10 / 11 / Server 2019+
