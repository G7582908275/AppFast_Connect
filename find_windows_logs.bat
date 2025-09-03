@echo off
echo Windows日志文件位置查找工具
echo ================================

echo.
echo 当前用户临时目录:
echo %TEMP%

echo.
echo 查找AppFast Connect日志目录...
if exist "%TEMP%\appfast_connect\logs" (
    echo 找到日志目录: %TEMP%\appfast_connect\logs
    echo.
    echo 日志文件列表:
    dir "%TEMP%\appfast_connect\logs\app_*.log" /O:D
    echo.
    echo 最新日志文件内容 (最后20行):
    echo ================================
    for /f "delims=" %%i in ('dir /b /o-d "%TEMP%\appfast_connect\logs\app_*.log" 2^>nul') do (
        echo 文件: %%i
        echo --------------------------------
        type "%TEMP%\appfast_connect\logs\%%i" | findstr /n "^" | findstr /b "[0-9]*:" | tail -20
        goto :found
    )
) else (
    echo 未找到日志目录: %TEMP%\appfast_connect\logs
    echo 可能的原因:
    echo 1. 应用尚未运行过
    echo 2. 日志目录被删除
    echo 3. 权限问题
)

:found
echo.
echo 按任意键退出...
pause >nul
