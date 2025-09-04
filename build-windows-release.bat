@echo off
setlocal enabledelayedexpansion

REM ========================================
REM AppFast Connect Windows 发行版本构建脚本
REM ========================================

REM 设置颜色代码
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "MAGENTA=[95m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"

REM 检查参数
if "%1"=="" (
    echo %RED%错误: 请提供版本号%RESET%
    echo 用法: %0 ^<版本号^> [构建号]
    echo 示例: %0 1.0.0 1
    echo 示例: %0 1.0.0
    exit /b 1
)

set VERSION=%1
set BUILD_NUMBER=%2

REM 如果没有提供构建号，使用默认值1
if "%BUILD_NUMBER%"=="" set BUILD_NUMBER=1

REM 验证版本号格式
echo %VERSION% | findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo %RED%错误: 版本号格式不正确，请使用 x.y.z 格式%RESET%
    echo 示例: 1.0.0, 2.1.3
    exit /b 1
)

echo %CYAN%========================================%RESET%
echo %CYAN%AppFast Connect Windows 发行版本构建%RESET%
echo %CYAN%版本: %VERSION%+%BUILD_NUMBER%%RESET%
echo %CYAN%========================================%RESET%

REM 检查Flutter环境
echo %BLUE%检查Flutter环境...%RESET%
flutter --version >nul 2>&1
if errorlevel 1 (
    echo %RED%错误: 未找到Flutter，请确保Flutter已安装并添加到PATH%RESET%
    exit /b 1
)

REM 检查Git环境
echo %BLUE%检查Git环境...%RESET%
git --version >nul 2>&1
if errorlevel 1 (
    echo %RED%错误: 未找到Git，请确保Git已安装并添加到PATH%RESET%
    exit /b 1
)

REM 检查是否有未提交的更改
echo %BLUE%检查Git状态...%RESET%
git status --porcelain | findstr /r "^" >nul
if not errorlevel 1 (
    echo %YELLOW%警告: 有未提交的更改%RESET%
    git status --short
    set /p "CONTINUE=是否继续构建? (y/N): "
    if /i not "!CONTINUE!"=="y" (
        echo %RED%构建已取消%RESET%
        exit /b 1
    )
)

REM 拉取最新代码
echo %BLUE%拉取最新代码...%RESET%
git pull
if errorlevel 1 (
    echo %RED%错误: Git pull 失败%RESET%
    exit /b 1
)

REM 创建构建目录
set BUILD_DIR=build\windows-release
if exist "%BUILD_DIR%" (
    echo %BLUE%清理旧的构建目录...%RESET%
    rmdir /s /q "%BUILD_DIR%"
)
mkdir "%BUILD_DIR%"

REM 复制内核文件
echo %BLUE%复制内核文件...%RESET%
call scripts\copy_kernel.bat
if errorlevel 1 (
    echo %RED%错误: 内核文件复制失败%RESET%
    exit /b 1
)

REM 清理旧的构建文件
echo %BLUE%清理旧的构建文件...%RESET%
flutter clean
if errorlevel 1 (
    echo %RED%错误: Flutter clean 失败%RESET%
    exit /b 1
)

REM 获取依赖
echo %BLUE%获取依赖...%RESET%
flutter pub get
if errorlevel 1 (
    echo %RED%错误: Flutter pub get 失败%RESET%
    exit /b 1
)

REM 更新版本号
echo %BLUE%更新版本号到 %VERSION%+%BUILD_NUMBER%...%RESET%
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .*', 'version: %VERSION%+%BUILD_NUMBER%' | Set-Content pubspec.yaml"
if errorlevel 1 (
    echo %RED%错误: 版本号更新失败%RESET%
    exit /b 1
)

REM 构建Windows应用
echo %BLUE%构建Windows应用...%RESET%
flutter build windows --release
if errorlevel 1 (
    echo %RED%错误: Windows构建失败%RESET%
    exit /b 1
)

REM 创建发布包
echo %BLUE%创建发布包...%RESET%
set RELEASE_NAME=AppFast_Connect_Windows_%VERSION%_%BUILD_NUMBER%
set RELEASE_DIR=%BUILD_DIR%\%RELEASE_NAME%

REM 创建发布目录
mkdir "%RELEASE_DIR%"

REM 复制构建文件
echo %BLUE%复制构建文件...%RESET%
xcopy "build\windows\runner\Release\*" "%RELEASE_DIR%\" /E /I /Y
if errorlevel 1 (
    echo %RED%错误: 文件复制失败%RESET%
    exit /b 1
)

REM 复制必要的运行时文件
echo %BLUE%复制运行时文件...%RESET%
if exist "assets\libs\core" (
    copy "assets\libs\core" "%RELEASE_DIR%\core.exe" >nul
)

REM 创建版本信息文件
echo %BLUE%创建版本信息文件...%RESET%
(
echo AppFast Connect Windows
echo 版本: %VERSION%
echo 构建号: %BUILD_NUMBER%
echo 构建时间: %date% %time%
echo 构建环境: Windows
) > "%RELEASE_DIR%\version.txt"

REM 创建README文件
echo %BLUE%创建README文件...%RESET%
(
echo AppFast Connect Windows 版本
echo ================================
echo.
echo 版本: %VERSION%
echo 构建号: %BUILD_NUMBER%
echo 构建时间: %date% %time%
echo.
echo 安装说明:
echo 1. 解压所有文件到任意目录
echo 2. 运行 AppFast_Connect.exe
echo 3. 首次运行可能需要管理员权限
echo.
echo 注意事项:
echo - 请确保Windows Defender不会误报
echo - 如遇到问题，请查看日志文件
echo.
echo 技术支持: 请联系开发团队
) > "%RELEASE_DIR%\README.txt"

REM 创建ZIP压缩包
echo %BLUE%创建ZIP压缩包...%RESET%
set ZIP_FILE=%BUILD_DIR%\%RELEASE_NAME%.zip
powershell -Command "Compress-Archive -Path '%RELEASE_DIR%' -DestinationPath '%ZIP_FILE%' -Force"
if errorlevel 1 (
    echo %RED%错误: ZIP压缩包创建失败%RESET%
    exit /b 1
)

REM 显示构建结果
echo.
echo %GREEN%========================================%RESET%
echo %GREEN%构建完成!%RESET%
echo %GREEN%========================================%RESET%
echo.
echo %CYAN%版本信息:%RESET%
echo   版本号: %VERSION%
echo   构建号: %BUILD_NUMBER%
echo   构建时间: %date% %time%
echo.
echo %CYAN%输出文件:%RESET%
echo   发布目录: %RELEASE_DIR%
echo   ZIP压缩包: %ZIP_FILE%
echo.
echo %CYAN%文件大小:%RESET%
for %%F in ("%ZIP_FILE%") do echo   ZIP压缩包: %%~zF 字节
echo.

REM 询问是否提交版本更改
set /p "COMMIT=是否提交版本更改到Git? (y/N): "
if /i "!COMMIT!"=="y" (
    echo %BLUE%提交版本更改...%RESET%
    git add pubspec.yaml
    git commit -m "Release version %VERSION%+%BUILD_NUMBER%"
    if errorlevel 1 (
        echo %YELLOW%警告: Git提交失败%RESET%
    ) else (
        echo %GREEN%版本更改已提交%RESET%
    )
)

REM 询问是否创建Git标签
set /p "TAG=是否创建Git标签? (y/N): "
if /i "!TAG!"=="y" (
    echo %BLUE%创建Git标签...%RESET%
    git tag "v%VERSION%"
    if errorlevel 1 (
        echo %YELLOW%警告: Git标签创建失败%RESET%
    ) else (
        echo %GREEN%Git标签 v%VERSION% 已创建%RESET%
    )
)

echo.
echo %GREEN%构建流程完成!%RESET%
echo %CYAN%您可以在以下位置找到构建文件:%RESET%
echo   %RELEASE_DIR%
echo   %ZIP_FILE%
echo.

pause
