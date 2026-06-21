@echo off
REM ============================================================
REM  Claude Code 企业模板 - Windows 一键安装脚本
REM  Project: internal-user-service 完整配置
REM  Version: 1.0
REM  Date: 2026-06-21
REM ============================================================

REM 启用 UTF-8 支持（解决中文乱码）
chcp 65001 > nul 2>&1

REM 启用延迟变量扩展
setlocal enabledelayedexpansion

REM 颜色代码（Windows 10+ 支持）
set "CLR_HEADER=0E"
set "CLR_OK=0A"
set "CLR_WARN=0C"
set "CLR_INFO=0B"
set "CLR_RESET=07"

title Claude Code Template Installer

REM ============================================================
REM  0. Banner
REM ============================================================
echo.
echo ============================================================
echo   Claude Code Enterprise Template - One-Click Installer
echo   internal-user-service  ^|^|  36 files ^|^|  v1.0
echo ============================================================
echo.

REM 脚本所在目录（关键：用 %~dp0 获得绝对路径）
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM 全局 Claude 配置目录
set "GLOBAL_CLAUDE=%USERPROFILE%\.claude"

REM ============================================================
REM  1. 环境检测
REM ============================================================
echo [1/5] [INFO] 检测环境...

REM 检查 Claude Code 是否安装
where claude >nul 2>&1
if %errorlevel% neq 0 (
    color %CLR_WARN%
    echo        [WARN] 未检测到 claude 命令
    echo        请先安装 Claude Code:
    echo        https://claude.com/install
    echo.
    set /p "CONTINUE=        继续安装? [y/N]: "
    if /i not "!CONTINUE!"=="y" (
        echo        [ERROR] 已取消
        pause
        exit /b 1
    )
    color %CLR_RESET%
) else (
    for /f "tokens=*" %%v in ('claude --version 2^>nul') do (
        echo        [OK] Claude Code 已安装: %%v
    )
)

REM 检查模板目录
if not exist "%SCRIPT_DIR%\.claude" (
    color %CLR_WARN%
    echo        [ERROR] 模板目录不存在: %SCRIPT_DIR%\.claude
    echo        请确保 install.bat 在 internal-project 根目录
    pause
    exit /b 1
)

REM 统计文件
set "FILE_COUNT=0"
for /r "%SCRIPT_DIR%\.claude" %%f in (*) do set /a "FILE_COUNT+=1"
for /r "%SCRIPT_DIR%\docs" %%f in (*) do set /a "FILE_COUNT+=1"
for /r "%SCRIPT_DIR%\.planning" %%f in (*) do set /a "FILE_COUNT+=1"
echo        [OK] 模板包含 !FILE_COUNT! 个文件
echo.

REM ============================================================
REM  2. 选择安装模式
REM ============================================================
:menu
echo [2/5] 请选择安装模式:
echo.
echo   [1] 项目级安装 (推荐)
echo       把 .claude/ 和 CLAUDE.md 复制到指定项目
echo.
echo   [2] 全局安装
echo       把 sub-agents / skills / commands 复制到 %%USERPROFILE%%\.claude\
echo       所有项目都能用 (settings.json 仍是项目级)
echo.
echo   [3] 模板项目
echo       复制整个 internal-project 到新位置作为新项目起点
echo.
echo   [4] 卸载已安装的
echo.
echo   [5] 查看详细帮助
echo.
echo   [0] 退出
echo.
set /p "MODE=        请选择 [0-5]: "

if "%MODE%"=="1" goto install_project
if "%MODE%"=="2" goto install_global
if "%MODE%"=="3" goto install_template
if "%MODE%"=="4" goto uninstall
if "%MODE%"=="5" goto help
if "%MODE%"=="0" goto exit_clean
goto menu_error

REM ============================================================
REM  Mode 1: 项目级安装
REM ============================================================
:install_project
echo.
echo [3/5] [INFO] 项目级安装模式
echo.

REM 询问目标路径
set "TARGET="
set /p "TARGET=        请输入目标项目绝对路径 (如 D:\projects\my-app): "
if "%TARGET%"=="" goto target_error

REM 去除尾部反斜杠
if "%TARGET:~-1%"=="\" set "TARGET=%TARGET:~0,-1%"

REM 检查路径是否存在
if not exist "%TARGET%" (
    echo        [WARN] 目录不存在: %TARGET%
    set /p "CREATE=        是否创建? [y/N]: "
    if /i "!CREATE!"=="y" (
        mkdir "%TARGET%" >nul 2>&1
        if !errorlevel! neq 0 goto target_error
        echo        [OK] 已创建目录
    ) else (
        goto target_error
    )
)

REM 检查现有 .claude/
set "TARGET_CLAUDE=%TARGET%\.claude"
if exist "%TARGET_CLAUDE%" (
    color %CLR_WARN%
    echo        [WARN] 目标已存在 .claude/
    set /p "OVERWRITE=        是否覆盖? [y/N]: "
    color %CLR_RESET%
    if /i not "!OVERWRITE!"=="y" (
        echo        已取消
        goto menu
    )
    REM 备份
    if exist "%TARGET_CLAUDE%.bak" rd /S /Q "%TARGET_CLAUDE%.bak"
    move "%TARGET_CLAUDE%" "%TARGET_CLAUDE%.bak" >nul
    echo        [INFO] 已备份到 .claude.bak
)

REM 复制 .claude/
echo        [INFO] 复制 .claude/ ...
xcopy /E /I /Y /Q "%SCRIPT_DIR%\.claude" "%TARGET_CLAUDE%" >nul
if !errorlevel! neq 0 (
    echo        [ERROR] 复制失败
    pause
    exit /b 1
)

REM 复制 CLAUDE.md
echo        [INFO] 复制 CLAUDE.md ...
if exist "%TARGET%\CLAUDE.md" (
    set /p "OVERWRITE_MD=        CLAUDE.md 已存在,覆盖? [y/N]: "
    if /i "!OVERWRITE_MD!"=="y" (
        copy /Y "%SCRIPT_DIR%\CLAUDE.md" "%TARGET%\CLAUDE.md" >nul
    )
) else (
    copy /Y "%SCRIPT_DIR%\CLAUDE.md" "%TARGET%\CLAUDE.md" >nul
)

REM 复制 docs/ (业务/架构/项目文档)
echo        [INFO] 复制 docs\internal-project\ (业务文档) ...
if not exist "%TARGET%\docs\internal-project" mkdir "%TARGET%\docs\internal-project" >nul
xcopy /E /I /Y /Q "%SCRIPT_DIR%\docs\requirements" "%TARGET%\docs\internal-project\requirements\" >nul
xcopy /E /I /Y /Q "%SCRIPT_DIR%\docs\domain" "%TARGET%\docs\internal-project\domain\" >nul
xcopy /E /I /Y /Q "%SCRIPT_DIR%\docs\architecture" "%TARGET%\docs\internal-project\architecture\" >nul
xcopy /E /I /Y /Q "%SCRIPT_DIR%\docs\project" "%TARGET%\docs\internal-project\project\" >nul

REM 复制 docs/api/ (OpenAPI spec — 独立路径, 不嵌套)
echo        [INFO] 复制 docs\api\ (OpenAPI spec) ...
if exist "%SCRIPT_DIR%\docs\api" (
    if not exist "%TARGET%\docs\api" mkdir "%TARGET%\docs\api" >nul
    xcopy /E /I /Y /Q "%SCRIPT_DIR%\docs\api" "%TARGET%\docs\api\" >nul
)

REM 复制 .planning/
echo        [INFO] 复制 .planning/ ...
if not exist "%TARGET%\.planning" mkdir "%TARGET%\.planning" >nul
xcopy /E /I /Y /Q "%SCRIPT_DIR%\.planning" "%TARGET%\.planning\" >nul

REM 复制 README
copy /Y "%SCRIPT_DIR%\README.md" "%TARGET%\CLAUDE-TEMPLATE-README.md" >nul

echo.
color %CLR_OK%
echo ============================================================
echo   [OK] 项目级安装成功!
echo ============================================================
color %CLR_RESET%
echo.
echo 安装位置: %TARGET%
echo.
echo 下一步:
echo   1. cd /d "%TARGET%"
echo   2. 编辑 CLAUDE.md (替换项目名/技术栈/规则)
echo   3. 编辑 docs/requirements/business-rules.md (按需)
echo   4. claude  启动 Claude Code
echo.
goto exit_clean

REM ============================================================
REM  Mode 2: 全局安装
REM ============================================================
:install_global
echo.
echo [3/5] [INFO] 全局安装模式
echo.
echo        全局目录: %GLOBAL_CLAUDE%
echo.

if not exist "%GLOBAL_CLAUDE%" mkdir "%GLOBAL_CLAUDE%" >nul

REM 复制 agents
echo        [INFO] 复制 agents/ ...
if exist "%SCRIPT_DIR%\.claude\agents" (
    if not exist "%GLOBAL_CLAUDE%\agents" mkdir "%GLOBAL_CLAUDE%\agents" >nul
    xcopy /E /I /Y /Q "%SCRIPT_DIR%\.claude\agents" "%GLOBAL_CLAUDE%\agents\" >nul
)

REM 复制 skills
echo        [INFO] 复制 skills/ ...
if exist "%SCRIPT_DIR%\.claude\skills" (
    if not exist "%GLOBAL_CLAUDE%\skills" mkdir "%GLOBAL_CLAUDE%\skills" >nul
    xcopy /E /I /Y /Q "%SCRIPT_DIR%\.claude\skills" "%GLOBAL_CLAUDE%\skills\" >nul
)

REM 复制 commands
echo        [INFO] 复制 commands/ ...
if exist "%SCRIPT_DIR%\.claude\commands" (
    if not exist "%GLOBAL_CLAUDE%\commands" mkdir "%GLOBAL_CLAUDE%\commands" >nul
    xcopy /E /I /Y /Q "%SCRIPT_DIR%\.claude\commands" "%GLOBAL_CLAUDE%\commands\" >nul
)

echo.
color %CLR_OK%
echo ============================================================
echo   [OK] 全局安装成功!
echo ============================================================
color %CLR_RESET%
echo.
echo 安装位置: %GLOBAL_CLAUDE%
echo.
echo 已安装 (所有项目可用):
echo   - sub-agents:  product-owner / architect / planner / tracker
echo                  security-reviewer / api-designer / test-engineer / db-migrator
echo   - skills:      decompose-requirement / plan-execution / update-progress / create-adr
echo                  deploy-staging / create-new-endpoint / run-incident
echo   - commands:    /plan /decompose /track /retro /pr-review /release /db-migrate
echo.
echo [NOTE] settings.json 和 hooks 是项目级,需要项目级安装
echo.
goto exit_clean

REM ============================================================
REM  Mode 3: 模板项目
REM ============================================================
:install_template
echo.
echo [3/5] [INFO] 模板项目模式
echo.

set "NEW_DIR="
set /p "NEW_DIR=        请输入新项目目录 (如 D:\projects\my-claude-app): "
if "%NEW_DIR%"=="" goto target_error

if "%NEW_DIR:~-1%"=="\" set "NEW_DIR=%NEW_DIR:~0,-1%"

if exist "%NEW_DIR%" (
    color %CLR_WARN%
    echo        [WARN] 目录已存在: %NEW_DIR%
    set /p "OVERWRITE=        是否清空后复制? [y/N]: "
    color %CLR_RESET%
    if /i not "!OVERWRITE!"=="y" goto menu
    rd /S /Q "%NEW_DIR%"
)

REM 复制整个目录（排除 install.bat）
echo        [INFO] 复制完整模板 ...
xcopy /E /I /Y /Q "%SCRIPT_DIR%\*" "%NEW_DIR%\" /EXCLUDE:%SCRIPT_DIR%\install.bat >nul

REM 删除 install.bat（避免在新项目中重复）
if exist "%NEW_DIR%\install.bat" del /Q "%NEW_DIR%\install.bat" >nul

REM 删除 docs\domain\entities 等的旧示例
echo        [INFO] 清理示例文件 ...
del /Q "%NEW_DIR%\README.md.bak" 2>nul

echo.
color %CLR_OK%
echo ============================================================
echo   [OK] 模板项目创建成功!
echo ============================================================
color %CLR_RESET%
echo.
echo 位置: %NEW_DIR%
echo.
echo 包含:
echo   - .claude/        (完整 Claude Code 配置)
echo   - CLAUDE.md       (项目记忆)
echo   - docs/           (业务/架构/项目文档)
echo   - .planning/      (任务规划系统)
echo.
echo 下一步:
echo   1. cd /d "%NEW_DIR%"
echo   2. 修改 CLAUDE.md (项目名/技术栈)
echo   3. 修改 docs/requirements/business-rules.md
echo   4. 初始化 git: git init
echo   5. claude 启动 Claude Code
echo.
goto exit_clean

REM ============================================================
REM  Mode 4: 卸载
REM ============================================================
:uninstall
echo.
echo [3/5] 卸载模式
echo.
echo   [1] 卸载项目级安装
echo   [2] 卸载全局安装
echo.
set /p "UMODE=        请选择 [1-2]: "

if "%UMODE%"=="1" (
    set /p "TARGET=        请输入目标项目路径: "
    if "!TARGET!"=="" goto target_error
    if "!TARGET:~-1!"=="\" set "TARGET=!TARGET:~0,-1!"

    echo.
    echo        将删除:
    echo          !TARGET!\.claude\
    echo          !TARGET!\.planning\
    echo          !TARGET!\CLAUDE.md
    echo          !TARGET!\docs\internal-project\
    echo.
    set /p "CONFIRM=        确认? [y/N]: "
    if /i not "!CONFIRM!"=="y" goto menu

    if exist "!TARGET!\.claude" rd /S /Q "!TARGET!\.claude"
    if exist "!TARGET!\.planning" rd /S /Q "!TARGET!\.planning"
    if exist "!TARGET!\CLAUDE.md" del /Q "!TARGET!\CLAUDE.md"
    if exist "!TARGET!\docs\internal-project" rd /S /Q "!TARGET!\docs\internal-project"
    if exist "!TARGET!\CLAUDE-TEMPLATE-README.md" del /Q "!TARGET!\CLAUDE-TEMPLATE-README.md"

    echo        [OK] 项目级已卸载
    goto exit_clean
)

if "%UMODE%"=="2" (
    echo.
    color %CLR_WARN%
    echo        [WARN] 全局卸载会删除所有自定义 sub-agents/skills/commands!
    echo        包括你自己创建的内容!
    color %CLR_RESET%
    echo.
    set /p "CONFIRM=        确认删除 %GLOBAL_CLAUDE%? [y/N]: "
    if /i not "!CONFIRM!"=="y" goto menu

    REM 备份
    if exist "%GLOBAL_CLAUDE%" (
        if exist "%GLOBAL_CLAUDE%.bak" rd /S /Q "%GLOBAL_CLAUDE%.bak"
        xcopy /E /I /Y /Q "%GLOBAL_CLAUDE%" "%GLOBAL_CLAUDE%.bak\" >nul
        echo        [INFO] 已备份到 .claude.bak
    )

    REM 只删除我们安装的内容（保留 settings 等）
    if exist "%GLOBAL_CLAUDE%\agents\product-owner.md" del /Q "%GLOBAL_CLAUDE%\agents\product-owner.md"
    if exist "%GLOBAL_CLAUDE%\agents\architect.md" del /Q "%GLOBAL_CLAUDE%\agents\architect.md"
    if exist "%GLOBAL_CLAUDE%\agents\planner.md" del /Q "%GLOBAL_CLAUDE%\agents\planner.md"
    if exist "%GLOBAL_CLAUDE%\agents\tracker.md" del /Q "%GLOBAL_CLAUDE%\agents\tracker.md"
    if exist "%GLOBAL_CLAUDE%\agents\security-reviewer.md" del /Q "%GLOBAL_CLAUDE%\agents\security-reviewer.md"
    if exist "%GLOBAL_CLAUDE%\agents\api-designer.md" del /Q "%GLOBAL_CLAUDE%\agents\api-designer.md"
    if exist "%GLOBAL_CLAUDE%\agents\test-engineer.md" del /Q "%GLOBAL_CLAUDE%\agents\test-engineer.md"
    if exist "%GLOBAL_CLAUDE%\agents\db-migrator.md" del /Q "%GLOBAL_CLAUDE%\agents\db-migrator.md"

    REM 删除 skills 目录
    for /d %%d in ("%GLOBAL_CLAUDE%\skills\deploy-staging", "%GLOBAL_CLAUDE%\skills\create-new-endpoint", "%GLOBAL_CLAUDE%\skills\run-incident", "%GLOBAL_CLAUDE%\skills\decompose-requirement", "%GLOBAL_CLAUDE%\skills\plan-execution", "%GLOBAL_CLAUDE%\skills\update-progress", "%GLOBAL_CLAUDE%\skills\create-adr") do (
        if exist %%d rd /S /Q %%d
    )

    REM 删除 commands
    for %%f in ("%GLOBAL_CLAUDE%\commands\plan.md", "%GLOBAL_CLAUDE%\commands\decompose.md", "%GLOBAL_CLAUDE%\commands\track.md", "%GLOBAL_CLAUDE%\commands\retro.md", "%GLOBAL_CLAUDE%\commands\pr-review.md", "%GLOBAL_CLAUDE%\commands\release.md", "%GLOBAL_CLAUDE%\commands\db-migrate.md") do (
        if exist %%f del /Q %%f
    )

    echo        [OK] 全局自定义内容已卸载
    echo        [INFO] 备份在: %GLOBAL_CLAUDE%.bak
    goto exit_clean
)

goto menu

REM ============================================================
REM  Help
REM ============================================================
:help
echo.
echo ============================================================
echo   详细帮助
echo ============================================================
echo.
echo 【模式 1: 项目级安装】 ^(推荐^)
echo   复制内容到指定项目:
echo     - .claude\         ^(agents + skills + commands + hooks + settings^)
echo     - CLAUDE.md        ^(项目记忆^)
echo     - docs\internal-project\   ^(业务/架构/项目文档^)
echo     - .planning\       ^(任务规划系统^)
echo.
echo   使用场景:
echo     - 给现有项目添加 Claude Code 企业级配置
echo     - 不影响其他项目
echo.
echo 【模式 2: 全局安装】
echo   复制到 %%USERPROFILE%%\.claude\:
echo     - agents\          ^(所有项目可用的子代理^)
echo     - skills\          ^(所有项目可用的技能^)
echo     - commands\        ^(所有项目可用的命令^)
echo.
echo   使用场景:
echo     - 想让所有项目都用同一个 sub-agent / skill
echo.
echo   注意:
echo     - settings.json 是项目级,不能全局
echo     - hooks 是 .sh 文件,Windows 不能直接跑
echo       (建议在 WSL 里用 Claude Code)
echo.
echo 【模式 3: 模板项目】
echo   复制整个 internal-project 到新位置
echo   使用场景:
echo     - 新建项目时作为起点
echo     - 学习 Claude Code 项目级最佳实践
echo.
echo 【模式 4: 卸载】
echo   反向清理已安装的文件
echo   默认会备份到 .bak
echo.
echo 【系统要求】
echo   - Windows 10 / 11 (或 Windows Server 2019+)
echo   - Claude Code ^(可选,未装也能安装配置^)
echo   - 如果用 hooks: WSL / Git Bash ^(因为是 .sh 脚本^)
echo.
echo.
goto menu

REM ============================================================
REM  错误处理
REM ============================================================
:menu_error
echo.
color %CLR_WARN%
echo        [ERROR] 无效选择: %MODE%
color %CLR_RESET%
echo.
goto menu

:target_error
echo.
color %CLR_WARN%
echo        [ERROR] 路径无效或创建失败
color %CLR_RESET%
echo.
goto menu

REM ============================================================
REM  Exit
REM ============================================================
:exit_clean
echo.
echo ============================================================
echo   完成!
echo ============================================================
echo.
pause
exit /b 0
