@echo off
setlocal enabledelayedexpansion

REM ========================================
REM AppFast Connect Windows 快速构建脚本
REM ========================================

REM 设置颜色代码
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "RESET=[0m"

echo %CYAN%开始快速构建...%RESET%

REM 检查Flutter环境
flutter --version >nul 2>&1
if errorlevel 1 (
    echo %RED%错误: 未找到Flutter%RESET%
    pause
    exit /b 1
)

REM 拉取最新代码
echo %BLUE%拉取最新代码...%RESET%
git pull

REM 复制内核文件
echo %BLUE%复制内核文件...%RESET%
call scripts\copy_kernel.bat

REM 清理并构建
echo %BLUE%清理旧文件...%RESET%
flutter clean

echo %BLUE%获取依赖...%RESET%
flutter pub get

echo %BLUE%构建Windows应用...%RESET%
flutter build windows --release

if errorlevel 1 (
    echo %RED%构建失败!%RESET%
    pause
    exit /b 1
)

echo.
echo %GREEN%构建完成!%RESET%
echo %CYAN%输出位置: build\windows\runner\Release\%RESET%
echo.

pause
