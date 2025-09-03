#!/bin/bash

echo "=== 测试各平台构建路径 ==="
echo

# 检查Flutter环境
echo "1. 检查Flutter环境..."
flutter --version
echo

# 清理之前的构建
echo "2. 清理之前的构建..."
flutter clean

# 复制内核文件
echo "3. 复制内核文件..."
./scripts/copy_kernel.sh

# 测试各平台构建
PLATFORMS=("windows" "macos" "linux")

for platform in "${PLATFORMS[@]}"; do
    echo "4. 测试 $platform 平台构建..."
    
    # 构建应用
    flutter build $platform --release
    
    # 检查构建输出路径
    echo "   $platform 构建输出目录结构："
    
    if [[ "$platform" == "windows" ]]; then
        BUILD_PATH="build/windows/runner/Release"
    elif [[ "$platform" == "macos" ]]; then
        BUILD_PATH="build/macos/Build/Products/Release"
    elif [[ "$platform" == "linux" ]]; then
        BUILD_PATH="build/linux/x64/release/bundle"
    fi
    
    echo "   预期路径: $BUILD_PATH"
    
    if [ -d "$BUILD_PATH" ]; then
        echo "   ✓ 路径存在"
        echo "   目录内容:"
        ls -la "$BUILD_PATH" | head -5
    else
        echo "   ✗ 路径不存在"
        echo "   可用的构建目录:"
        find build -type d -name "*$platform*" | head -5
    fi
    
    echo
done

echo "=== 测试完成 ==="
