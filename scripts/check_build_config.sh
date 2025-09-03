#!/bin/bash

echo "=== AppFast Connect 构建配置检查 ==="
echo

# 检查Flutter版本
echo "1. 检查Flutter版本："
flutter --version
echo

# 检查支持的平台
echo "2. 检查Flutter支持的平台："
flutter config --list
echo

# 检查当前平台
echo "3. 当前平台信息："
echo "操作系统: $(uname -s)"
echo "架构: $(uname -m)"
echo "平台: $(uname -s | tr '[:upper:]' '[:lower:]')"
echo

# 检查sing-box内核文件
echo "4. 检查sing-box内核文件："
if [ -d "sing-box" ]; then
    echo "找到sing-box目录，包含以下文件："
    ls -la sing-box/
else
    echo "错误: 找不到sing-box目录"
fi
echo

# 检查assets目录
echo "5. 检查assets目录结构："
if [ -d "assets" ]; then
    echo "assets目录结构："
    find assets -type f | head -10
else
    echo "错误: 找不到assets目录"
fi
echo

# 检查pubspec.yaml
echo "6. 检查pubspec.yaml配置："
if [ -f "pubspec.yaml" ]; then
    echo "pubspec.yaml存在"
    echo "应用名称: $(grep '^name:' pubspec.yaml | cut -d: -f2 | tr -d ' ')"
    echo "版本: $(grep '^version:' pubspec.yaml | cut -d: -f2 | tr -d ' ')"
else
    echo "错误: 找不到pubspec.yaml"
fi
echo

echo "=== 检查完成 ==="
