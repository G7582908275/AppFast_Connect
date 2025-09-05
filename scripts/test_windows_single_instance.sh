#!/bin/bash

# Windows 单实例功能测试脚本
# 用于验证修复后的单实例运行功能

echo "=== AppFast Connect Windows 单实例功能测试 ==="
echo ""

# 检查当前平台
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="Windows"
    echo "检测到平台: $PLATFORM"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    echo "检测到平台: $PLATFORM"
else
    PLATFORM="Linux"
    echo "检测到平台: $PLATFORM (单实例功能不适用)"
fi

echo ""

if [[ "$PLATFORM" == "Windows" ]]; then
    echo "Windows 单实例测试说明:"
    echo "1. 运行应用后，尝试再次启动应用"
    echo "2. 第二个实例应该立即退出，不会创建窗口"
    echo "3. 检查控制台输出确认单实例检查是否正常工作"
    echo ""
    echo "测试步骤:"
    echo "1. 在第一个命令提示符中运行:"
    echo "   flutter run -d windows"
    echo ""
    echo "2. 等待第一个实例完全启动后，在另一个命令提示符中运行:"
    echo "   flutter run -d windows"
    echo ""
    echo "3. 预期结果:"
    echo "   - 第一个实例正常启动并显示界面"
    echo "   - 第二个实例应该显示 'App is already running' 并立即退出"
    echo "   - 第二个实例不应该创建任何窗口或托盘图标"
    
elif [[ "$PLATFORM" == "macOS" ]]; then
    echo "macOS 单实例测试说明:"
    echo "1. 运行应用后，尝试再次启动应用"
    echo "2. 第二个实例应该立即退出，不会创建窗口"
    echo "3. 检查控制台输出确认单实例检查是否正常工作"
    echo ""
    echo "测试步骤:"
    echo "1. 在第一个终端中运行:"
    echo "   flutter run -d macos"
    echo ""
    echo "2. 等待第一个实例完全启动后，在另一个终端中运行:"
    echo "   flutter run -d macos"
    echo ""
    echo "3. 预期结果:"
    echo "   - 第一个实例正常启动并显示界面"
    echo "   - 第二个实例应该显示 'App is already running' 并立即退出"
    echo "   - 第二个实例不应该创建任何窗口或托盘图标"
    
else
    echo "Linux 平台不需要单实例功能测试"
fi

echo ""
echo "=== 修复说明 ==="
echo "修复内容:"
echo "- 将单实例检查移到平台初始化之前"
echo "- 只有第一个实例才会进行平台初始化（窗口创建、托盘服务等）"
echo "- 后续实例会立即退出，不会创建任何系统资源"
echo ""
echo "=== 测试完成 ==="
