@echo off
setlocal enabledelayedexpansion

REM 获取系统架构
for /f "tokens=*" %%i in ('wmic os get osarchitecture /value ^| find "="') do set %%i
if "%OSArchitecture%"=="64-bit" (
    set ARCH=amd64
) else (
    set ARCH=arm64
)

REM 构建内核文件名
set KERNEL_FILE=appfast-singbox_windows_%ARCH%.exe

REM 检查内核文件是否存在
if not exist "sing-box\%KERNEL_FILE%" (
    echo 错误: 找不到内核文件 sing-box\%KERNEL_FILE%
    echo 当前架构: %ARCH%
    echo 可用的内核文件:
    dir sing-box\
    exit /b 1
)

REM 创建目标目录
if not exist "assets\libs" mkdir "assets\libs"

REM 复制内核文件
echo 复制内核文件: %KERNEL_FILE%
copy "sing-box\%KERNEL_FILE%" "assets\libs\core"

echo 内核文件复制完成: assets\libs\core
