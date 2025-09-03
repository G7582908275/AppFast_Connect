#!/bin/bash

echo "=== 测试Linux构建路径 ==="
echo

# 检查是否为Linux系统
if [[ "$(uname)" != "Linux" ]]; then
    echo "注意: 此脚本主要用于Linux系统，当前系统: $(uname)"
    echo "但我们可以模拟构建过程来检查路径"
fi

echo "1. 清理之前的构建..."
flutter clean

echo "2. 复制内核文件..."
./scripts/copy_kernel.sh

echo "3. 构建Linux应用..."
flutter build linux --release

echo "4. 检查构建输出目录结构..."
echo "构建目录:"
find build -type d -name "*linux*" | head -10

echo
echo "构建文件:"
find build -name "*linux*" -type f | head -10

echo
echo "5. 检查bundle目录内容..."
if [ -d "build/linux/x64/release/bundle" ]; then
    echo "✓ 找到bundle目录"
    echo "bundle目录内容:"
    ls -la build/linux/x64/release/bundle/
else
    echo "✗ 未找到bundle目录"
    echo "可用的Linux构建目录:"
    find build -name "*linux*" -type d
fi

echo
echo "=== 测试完成 ==="
