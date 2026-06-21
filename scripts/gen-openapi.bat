@echo off
REM ============================================================
REM  OpenAPI 代码生成脚本 (Windows)
REM  从 docs/api/openapi.yaml 生成代码
REM ============================================================

setlocal enabledelayedexpansion

cd /d "%~dp0\.."

set "SPEC=docs\api\openapi.yaml"
set "OUT_DIR=generated"
set "LANG=%~1"
if "%LANG%"=="" set "LANG=python"

echo ============================================================
echo   OpenAPI 代码生成器 (Windows)
echo   Spec: %SPEC%
echo   Language: %LANG%
echo ============================================================
echo.

if not exist "%SPEC%" (
    echo [ERROR] Spec not found: %SPEC%
    pause
    exit /b 1
)

where npx >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Node.js / npm 未安装
    echo         下载: https://nodejs.org
    pause
    exit /b 1
)

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo [INFO] 生成中...
npx --yes @openapitools/openapi-generator-cli generate ^
    -i "%SPEC%" ^
    -g %LANG% ^
    -o "%OUT_DIR%\%LANG%" ^
    --skip-validate-spec 2>nul

if %ERRORLEVEL% neq 0 (
    echo [ERROR] 生成失败
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   [OK] 生成完成
echo ============================================================
echo.
echo 位置: %OUT_DIR%\%LANG%
echo.
pause
