#!/bin/bash

# 获取当前平台和架构
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# 映射架构名称
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
fi

# 映射平台名称
if [ "$PLATFORM" = "darwin" ]; then
    PLATFORM="darwin"
elif [ "$PLATFORM" = "linux" ]; then
    PLATFORM="linux"
elif [[ "$PLATFORM" == *"NT"* ]] || [[ "$PLATFORM" == *"MINGW"* ]]; then
    PLATFORM="windows"
fi

# 构建内核文件名
if [ "$PLATFORM" = "windows" ]; then
    KERNEL_FILE="appfast-singbox_windows_${ARCH}.exe"
else
    KERNEL_FILE="appfast-singbox_${PLATFORM}_${ARCH}"
fi

# 检查内核文件是否存在
if [ ! -f "sing-box/$KERNEL_FILE" ]; then
    echo "错误: 找不到内核文件 sing-box/$KERNEL_FILE"
    echo "当前平台: $PLATFORM"
    echo "当前架构: $ARCH"
    echo "可用的内核文件:"
    ls -la sing-box/
    exit 1
fi

# 创建目标目录
mkdir -p assets/libs

# 复制内核文件
echo "复制内核文件: $KERNEL_FILE"
cp "sing-box/$KERNEL_FILE" "assets/libs/core"

# 设置执行权限（Linux和macOS）
if [ "$PLATFORM" != "windows" ]; then
    chmod +x "assets/libs/core"
fi

echo "内核文件复制完成: assets/libs/core"
