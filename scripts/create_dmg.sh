#!/bin/bash

# DMG 打包脚本
# 用法: ./create_dmg.sh [版本号]
# 示例: ./create_dmg.sh 1.0.0

set -e

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <版本号>"
    echo "示例: $0 1.0.0"
    exit 1
fi

VERSION=$1
APP_NAME="AppFast Connect"
APP_BUNDLE="build/macos/Build/Products/Release/${APP_NAME}.app"
DMG_NAME="AppFast_Connect_${VERSION}.dmg"
DMG_PATH="build/macos/${DMG_NAME}"

echo "开始创建 DMG 文件..."
echo "版本: $VERSION"
echo "应用: $APP_BUNDLE"
echo "输出: $DMG_PATH"

# 检查应用是否存在
if [ ! -d "$APP_BUNDLE" ]; then
    echo "错误: 应用文件不存在: $APP_BUNDLE"
    echo "请先运行: flutter build macos --release"
    exit 1
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
echo "临时目录: $TEMP_DIR"

# 复制应用到临时目录
cp -R "$APP_BUNDLE" "$TEMP_DIR/"

# 创建 Applications 符号链接
ln -s /Applications "$TEMP_DIR/Applications"

# 创建 DMG
echo "创建 DMG 文件..."
hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG_PATH"

# 清理临时目录
rm -rf "$TEMP_DIR"

echo "DMG 创建完成: $DMG_PATH"

# 显示 DMG 信息
echo ""
echo "DMG 信息:"
ls -lh "$DMG_PATH"
echo ""
echo "文件大小: $(du -h "$DMG_PATH" | cut -f1)"

# 验证 DMG
echo ""
echo "验证 DMG..."
hdiutil verify "$DMG_PATH"

echo ""
echo "✅ DMG 创建成功!"
echo "📁 文件位置: $DMG_PATH"
echo ""
echo "⚠️  注意: 当前使用 Apple Development 证书签名"
echo "   如需对外分发，请使用 Developer ID Application 证书"
echo "   并完成公证 (Notarization) 流程"
