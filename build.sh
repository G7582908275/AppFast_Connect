#!/bin/bash
# compress_dmg.sh

rm -fr /tmp/appfast_connect

# Build the app
flutter clean
flutter build macos --release

# Compress the DMG
APP_PATH="build/macos/Build/Products/Release/Appfast Connect.app"


# 判断当前环境并复制对应的 sing-box 内核到 App 包内
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    OUTPUT_DMG="AppFast_Connect_macos_arm64.dmg"
    KERNEL_FILE="appfast-core_darwin_arm64"
elif [ "$ARCH" = "x86_64" ]; then
    OUTPUT_DMG="AppFast_Connect_macos_amd64.dmg"
    KERNEL_FILE="appfast-core_darwin_amd64"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

SINGBOX_SRC="sing-box/$KERNEL_FILE"
DEST_DIR="$APP_PATH/Contents/MacOS"
DEST_FILE="$DEST_DIR/appfast-core"

if [ ! -f "$SINGBOX_SRC" ]; then
    echo "错误: 未找到内核文件 $SINGBOX_SRC"
    exit 1
fi

echo "复制 sing-box 内核 ($SINGBOX_SRC) 到 $DEST_FILE"
cp "$SINGBOX_SRC" "$DEST_FILE"
chmod +x "$DEST_FILE"


echo "开始压缩DMG..."

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "错误: 应用不存在 $APP_PATH"
    exit 1
fi

# 清理应用包中的不必要文件
echo "清理应用包..."
find "$APP_PATH" -name "*.dSYM" -delete 2>/dev/null || true
find "$APP_PATH" -name "*.log" -delete 2>/dev/null || true

# 创建临时目录用于DMG内容
TEMP_DMG_DIR="/tmp/appfast_connect_dmg"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# 复制应用到临时目录
echo "复制应用到临时目录..."
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# 创建 Applications 目录的快捷方式
echo "创建 Applications 快捷方式..."
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# 创建高度压缩的DMG
echo "创建压缩DMG..."
hdiutil create -volname "AppFast Connect" -srcfolder "$TEMP_DMG_DIR" -ov -format UDCO "$OUTPUT_DMG"

# 显示压缩结果
if [ -f "$OUTPUT_DMG" ]; then
    ORIGINAL_SIZE=$(du -h "$APP_PATH" | cut -f1)
    DMG_SIZE=$(du -h "$OUTPUT_DMG" | cut -f1)
    echo "压缩完成!"
    echo "原始应用大小: $ORIGINAL_SIZE"
    echo "DMG文件大小: $DMG_SIZE"
else
    echo "DMG创建失败"
    exit 1
fi