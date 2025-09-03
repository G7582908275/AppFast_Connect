#!/bin/bash

echo "=== 安装Linux构建依赖 ==="
echo

# 检查是否为Linux系统
if [[ "$(uname)" != "Linux" ]]; then
    echo "错误: 此脚本只能在Linux系统上运行"
    echo "当前系统: $(uname)"
    exit 1
fi

echo "正在更新包管理器..."
sudo apt-get update

echo "正在安装Flutter Linux桌面构建依赖..."
sudo apt-get install -y \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libsecret-1-dev \
    libblkid-dev \
    liblzma-dev \
    libsqlite3-dev \
    libayatana-appindicator3-dev \
    libx11-dev \
    libxrandr-dev \
    libxss-dev

if [ $? -eq 0 ]; then
    echo "✓ Linux依赖安装成功"
    echo
    echo "现在可以构建Linux应用了："
    echo "flutter build linux --release"
else
    echo "✗ Linux依赖安装失败"
    exit 1
fi

echo
echo "=== 安装完成 ==="
