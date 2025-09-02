#!/bin/bash
# compress_dmg.sh

rm -fr /tmp/appfast_connect

# Build the app
flutter clean
flutter build macos --release

# Compress the DMG
APP_PATH="build/macos/Build/Products/Release/Appfast Connect.app"
OUTPUT_DMG="AppFast_Connect_compressed.dmg"

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

# 创建高度压缩的DMG
echo "创建压缩DMG..."
hdiutil create -volname "AppFast Connect" -srcfolder "$APP_PATH" -ov -format UDCO "$OUTPUT_DMG"

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