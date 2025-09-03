#!/bin/bash

echo "=== 启用Flutter桌面平台 ==="
echo

# 启用Windows桌面版
echo "1. 启用Windows桌面版..."
flutter config --enable-windows-desktop
echo "Windows桌面版已启用"
echo

# 启用Linux桌面版
echo "2. 启用Linux桌面版..."
flutter config --enable-linux-desktop
echo "Linux桌面版已启用"
echo

# 检查配置
echo "3. 检查当前配置："
flutter config --list
echo

echo "=== 平台启用完成 ==="
echo "现在可以构建所有支持的平台了"
