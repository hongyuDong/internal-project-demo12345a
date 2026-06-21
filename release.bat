@echo off
REM ============================================================
REM  Claude Code 企业模板 - 版本发布脚本 (Windows)
REM  Usage: release.bat v1.1.0
REM ============================================================

chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

cd /d "%~dp0"

REM === 参数 ===
set "VERSION=%~1"
if "%VERSION%"=="" (
    set /p "VERSION=       输入新版本号 [如 v1.1.0]: "
)

if "%VERSION%"=="" (
    echo [ERROR] 版本号不能为空
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   发布版本: %VERSION%
echo ============================================================
echo.

REM === 1. 预检查 ===
echo [1/5] 预检查...

for /f "tokens=*" %%b in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%b"
if /i not "%BRANCH%"=="main" if /i not "%BRANCH%"=="master" (
    echo [ERROR] 当前在 %BRANCH% 分支
    pause
    exit /b 1
)

git diff --quiet
if %errorlevel% neq 0 (
    echo [ERROR] 工作区有未提交修改
    git status --short
    pause
    exit /b 1
)

echo        [OK] 检查通过
echo.

REM === 2. 更新版本号 ===
echo [2/5] 更新版本号...

powershell -Command "(Get-Content README.md -Raw) -replace 'Version.*v[0-9]+\.[0-9]+\.[0-9]+', 'Version: %VERSION%' | Set-Content README.md" >nul 2>&1

echo        [OK] 版本号: %VERSION%
echo.

REM === 3. 提交 + tag ===
echo [3/5] 提交 + tag...

git add .
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "chore(release): %VERSION%"
)

git tag -a "%VERSION%" -m "Release %VERSION%"

echo        [OK] Tag: %VERSION%
echo.

REM === 4. 推送 ===
echo [4/5] 推送...

git push origin %BRANCH%
git push origin "%VERSION%"

echo        [OK] 推送完成
echo.

REM === 5. Release ===
echo [5/5] 创建 GitHub Release...

where gh >nul 2>&1
if %errorlevel% equ 0 (
    set /p "USE_GH=        用 gh CLI 创建 Release? [Y/n]: "
    if /i not "!USE_GH!"=="n" (
        gh release create "%VERSION%" --title "%VERSION%" --notes "See CHANGELOG.md" --target "%BRANCH%"
        echo        [OK] Release 创建
    )
) else (
    echo        [INFO] 手动创建 Release:
    echo        https://github.com/your-org/your-repo/releases/new
)

echo.
echo ============================================================
echo   [OK] 发布完成: %VERSION%
echo ============================================================
echo.
pause
exit /b 0
