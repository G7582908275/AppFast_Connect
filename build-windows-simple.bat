@echo off
setlocal enabledelayedexpansion

REM ========================================
REM AppFast Connect Windows 基础构建脚本
REM ========================================

REM 设置颜色代码
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "RESET=[0m"

echo %CYAN%开始构建Windows应用...%RESET%

REM 检查Flutter环境
echo %BLUE%检查Flutter环境...%RESET%
flutter --version >nul 2>&1
if errorlevel 1 (
    echo %RED%错误: 未找到Flutter，请确保Flutter已安装并添加到PATH%RESET%
    pause
    exit /b 1
)

REM 拉取最新代码
echo %BLUE%拉取最新代码...%RESET%
git pull
if errorlevel 1 (
    echo %YELLOW%警告: Git pull 失败，继续构建...%RESET%
)

REM 复制内核文件
echo %BLUE%复制内核文件...%RESET%
call scripts\copy_kernel.bat
if errorlevel 1 (
    echo %YELLOW%警告: 内核文件复制失败，继续构建...%RESET%
)

REM 清理旧的构建文件
echo %BLUE%清理旧的构建文件...%RESET%
flutter clean
if errorlevel 1 (
    echo %YELLOW%警告: Flutter clean 失败，继续构建...%RESET%
)

REM 获取依赖
echo %BLUE%获取依赖...%RESET%
flutter pub get
if errorlevel 1 (
    echo %RED%错误: Flutter pub get 失败%RESET%
    pause
    exit /b 1
)

REM 构建Windows应用
echo %BLUE%构建Windows应用...%RESET%
flutter build windows --release
if errorlevel 1 (
    echo %RED%错误: Windows构建失败%RESET%
    pause
    exit /b 1
)

echo.
echo %GREEN%========================================%RESET%
echo %GREEN%构建完成!%RESET%
echo %GREEN%========================================%RESET%
echo.
echo %CYAN%输出位置: build\windows\runner\Release\%RESET%
echo.

pause
