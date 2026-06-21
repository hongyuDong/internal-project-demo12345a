@echo off
REM ============================================================
REM  Claude Code 企业模板 - 快速卸载
REM ============================================================

chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

title Claude Code Template Uninstaller

echo.
echo ============================================================
echo   Claude Code Enterprise Template - Uninstaller
echo ============================================================
echo.

REM 选择卸载类型
echo 请选择卸载类型:
echo.
echo   [1] 项目级 - 删除指定项目中的 .claude/ + CLAUDE.md + docs\internal-project\
echo   [2] 全局级 - 删除 %%USERPROFILE%%\.claude\ 中的本模板内容
echo.
set /p "MODE=   请选择 [1-2]: "

if "%MODE%"=="1" goto uninstall_project
if "%MODE%"=="2" goto uninstall_global
goto end

:uninstall_project
set /p "TARGET=   请输入目标项目路径: "
if "!TARGET!"=="" goto error
if "!TARGET:~-1!"=="\" set "TARGET=!TARGET:~0,-1!"

echo.
echo   将删除:
echo     !TARGET!\.claude\
echo     !TARGET%\CLAUDE.md
echo     !TARGET!\CLAUDE-TEMPLATE-README.md
echo     !TARGET!\docs\internal-project\
echo     !TARGET!\docs\api\
echo     !TARGET!\.planning\
echo.
set /p "CONFIRM=   确认删除? [y/N]: "
if /i not "!CONFIRM!"=="y" goto end

if exist "!TARGET!\.claude" rd /S /Q "!TARGET!\.claude"
if exist "!TARGET%\CLAUDE.md" del /Q "!TARGET%\CLAUDE.md"
if exist "!TARGET%\CLAUDE-TEMPLATE-README.md" del /Q "!TARGET%\CLAUDE-TEMPLATE-README.md"
if exist "!TARGET!\docs" (
    for %%d in (requirements domain architecture project api runbook testing) do (
        if exist "!TARGET!\docs\%%d" rd /S /Q "!TARGET!\docs\%%d"
    )
)
if exist "!TARGET!\docs\api" rd /S /Q "!TARGET!\docs\api"
if exist "!TARGET%\.planning" rd /S /Q "!TARGET%\.planning"

echo.
echo   [OK] 项目级已卸载
goto end

:uninstall_global
echo.
echo   [WARN] 将删除本模板安装的全局 sub-agents / skills / commands
echo   你自己创建的不会被删
echo.
set /p "CONFIRM=   确认? [y/N]: "
if /i not "!CONFIRM!"=="y" goto end

set "GLOBAL=%USERPROFILE%\.claude"

REM 删除本模板安装的 agents
for %%f in (product-owner architect planner tracker security-reviewer api-designer test-engineer db-migrator) do (
    if exist "%GLOBAL%\agents\%%f.md" del /Q "%GLOBAL%\agents\%%f.md" >nul 2>&1
)

REM 删除本模板安装的 skills
for %%d in (deploy-staging create-new-endpoint run-incident decompose-requirement plan-execution update-progress create-adr) do (
    if exist "%GLOBAL%\skills\%%d" rd /S /Q "%GLOBAL%\skills\%%d" >nul 2>&1
)

REM 删除本模板安装的 commands
for %%f in (plan decompose track retro pr-review release db-migrate) do (
    if exist "%GLOBAL%\commands\%%f.md" del /Q "%GLOBAL%\commands\%%f.md" >nul 2>&1
)

echo.
echo   [OK] 全局已卸载
goto end

:error
echo.
echo   [ERROR] 操作失败
goto end

:end
echo.
pause
exit /b 0
