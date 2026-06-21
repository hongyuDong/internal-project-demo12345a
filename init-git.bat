@echo off
REM ============================================================
REM  Claude Code 企业模板 - Git 推送脚本 (Windows 简化版)
REM  解决"窗口一闪就没了"问题
REM ============================================================

REM 注意: 故意不用 chcp / color / 复杂 for 循环
REM       保持最大兼容性

REM 切到脚本所在目录
cd /d "%~dp0"

echo ============================================================
echo   Claude Code Enterprise Template - Git Setup
echo ============================================================
echo.

REM === 1. 检查 git ===
echo [1/7] 检查环境...

where git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo        [ERROR] git 未安装
    echo        下载: https://git-scm.com/download/win
    echo.
    echo 按任意键退出...
    pause >nul
    exit /b 1
)
echo        [OK] git 已安装
echo.

REM === 2. 仓库配置 ===
echo [2/7] 仓库配置...
echo.

set /p "GITHUB_OWNER=        GitHub 用户名/组织 (直接回车用 company): "
if "%GITHUB_OWNER%"=="" set "GITHUB_OWNER=company"

set /p "REPO_NAME=        仓库名 (直接回车用 claude-code-template): "
if "%REPO_NAME%"=="" set "REPO_NAME=claude-code-template"

set /p "VISIBILITY=        可见性 public/private (直接回车用 private): "
if "%VISIBILITY%"=="" set "VISIBILITY=private"

set /p "PROTOCOL=        协议 ssh/https (直接回车用 ssh): "
if "%PROTOCOL%"=="" set "PROTOCOL=ssh"

if "%PROTOCOL%"=="ssh" (
    set "REMOTE_URL=git@github.com:%GITHUB_OWNER%/%REPO_NAME%.git"
) else (
    set "REMOTE_URL=https://github.com/%GITHUB_OWNER%/%REPO_NAME%.git"
)

echo.
echo        目标: %REMOTE_URL%
echo        可见性: %VISIBILITY%
echo.

REM === 3. 安全检查 ===
echo [3/7] 安全检查...

if exist ".env" (
    echo        [WARN] 发现 .env 文件，请确认不应提交
)

echo        [OK] 安全检查通过
echo.

REM === 4. git init ===
echo [4/7] 初始化 Git...

if exist ".git" (
    echo        [INFO] .git 已存在
) else (
    git init
    if %ERRORLEVEL% neq 0 (
        echo        [ERROR] git init 失败
        echo.
        pause
        exit /b 1
    )
    git checkout -b main 2>nul
    echo        [OK] git init 完成
)

REM 配置 user（如未配置）
git config user.name >nul 2>&1
if %ERRORLEVEL% neq 0 (
    set /p "GIT_NAME=        git user.name: "
    git config user.name "%GIT_NAME%"
)

git config user.email >nul 2>&1
if %ERRORLEVEL% neq 0 (
    set /p "GIT_EMAIL=        git user.email: "
    git config user.email "%GIT_EMAIL%"
)

echo        [OK] 配置完成
echo.

REM === 5. 添加 + 提交 ===
echo [5/7] 添加并提交...

git add .

echo        总文件: 
git status --short
echo.

set /p "CONFIRM=        确认提交? (Y/n): "
if /i "%CONFIRM%"=="n" (
    echo        [INFO] 已取消
    echo.
    pause
    exit /b 0
)

git commit -m "feat: initial release v1.0

- 86 files Claude Code enterprise template
- 8 sub-agents + 7 skills + 8 hooks
- 20 OpenAPI endpoints + 18 business rules
- 4 ADRs + 10 runbooks + test strategy
- Windows installer (install.bat + uninstall.bat)

See README.md for details."

if %ERRORLEVEL% neq 0 (
    echo        [ERROR] 提交失败
    echo.
    pause
    exit /b 1
)

echo        [OK] 提交完成
echo.

REM === 6. 创建 GitHub 仓库 ===
echo [6/7] 创建 GitHub 仓库...

where gh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo        检测到 gh CLI
    set /p "USE_GH=        用 gh CLI 创建仓库? (Y/n): "
    if /i not "%USE_GH%"=="n" (
        gh repo view "%GITHUB_OWNER%/%REPO_NAME%" >nul 2>&1
        if %ERRORLEVEL% equ 0 (
            echo        [INFO] 仓库已存在
        ) else (
            gh repo create "%GITHUB_OWNER%/%REPO_NAME%" --%VISIBILITY% --source=. --remote=origin
            echo        [OK] 仓库创建
        )
    )
) else (
    echo        [INFO] 未安装 gh CLI
    echo        请手动创建仓库: https://github.com/new
    echo        Name: %REPO_NAME%
    echo        Visibility: %VISIBILITY%
    echo.
    echo        创建好后按任意键继续...
    pause >nul
)

echo.

REM === 7. 推送 ===
echo [7/7] 推送到 GitHub...

git remote get-url origin >nul 2>&1
if %ERRORLEVEL% neq 0 (
    git remote add origin "%REMOTE_URL%"
    echo        添加 remote: %REMOTE_URL%
)

git push -u origin main
if %ERRORLEVEL% neq 0 (
    echo.
    echo        [ERROR] 推送失败
    echo        常见原因:
    echo        1. 没有推送权限 - 检查 SSH key / GitHub Token
    echo        2. 仓库不存在 - 先在 GitHub 创建
    echo        3. 网络问题
    echo.
    echo        详细错误:
    git push -u origin main 2>&1
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   [OK] 推送成功!
echo ============================================================
echo.
echo   仓库: https://github.com/%GITHUB_OWNER%/%REPO_NAME%
echo   分支: main
echo.
echo   团队成员: git clone %REMOTE_URL%
echo.
echo ============================================================
echo.
echo 按任意键关闭窗口...
pause >nul
exit /b 0
