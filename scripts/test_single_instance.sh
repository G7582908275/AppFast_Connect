#!/bin/bash

# 单实例功能测试脚本
# 用于验证 Windows 和 macOS 平台的单实例运行功能

echo "=== AppFast Connect 单实例功能测试 ==="
echo ""

# 检查当前平台
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    echo "检测到平台: $PLATFORM"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="Windows"
    echo "检测到平台: $PLATFORM"
else
    PLATFORM="Linux"
    echo "检测到平台: $PLATFORM (单实例功能不适用)"
fi

echo ""

if [[ "$PLATFORM" == "macOS" ]]; then
    echo "macOS 单实例测试说明:"
    echo "1. 运行应用后，尝试再次启动应用"
    echo "2. 第二个实例应该自动退出"
    echo "3. 检查日志文件确认单实例检查是否正常工作"
    echo ""
    echo "测试命令:"
    echo "flutter run -d macos"
    echo ""
    echo "在另一个终端中再次运行相同命令测试单实例功能"
    
elif [[ "$PLATFORM" == "Windows" ]]; then
    echo "Windows 单实例测试说明:"
    echo "1. 运行应用后，尝试再次启动应用"
    echo "2. 第二个实例应该自动退出"
    echo "3. 检查日志文件确认单实例检查是否正常工作"
    echo ""
    echo "测试命令:"
    echo "flutter run -d windows"
    echo ""
    echo "在另一个命令提示符中再次运行相同命令测试单实例功能"
    
else
    echo "Linux 平台不需要单实例功能测试"
fi

echo ""
echo "=== 测试完成 ==="
