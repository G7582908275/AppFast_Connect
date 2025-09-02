#!/bin/bash

# AppFast Connect DMG 打包脚本

# 设置变量
APP_NAME="AppFast Connect"
DMG_NAME="${APP_NAME// /_}.dmg"
BUILD_DIR="build/macos/Build/Products/Release"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_PATH="build/${DMG_NAME}"
TEMP_DMG_DIR="build/temp_dmg"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始构建 AppFast Connect DMG...${NC}"

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}错误: Flutter 未安装或不在PATH中${NC}"
    exit 1
fi

# 清理之前的构建
echo -e "${YELLOW}清理之前的构建...${NC}"
flutter clean

# 获取依赖
echo -e "${YELLOW}获取依赖...${NC}"
flutter pub get

# 构建macOS应用
echo -e "${YELLOW}构建macOS应用...${NC}"
flutter build macos --release

# 检查应用是否构建成功
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}错误: 应用构建失败，找不到 $APP_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}应用构建成功: $APP_PATH${NC}"

# 创建临时DMG目录
echo -e "${YELLOW}创建DMG目录结构...${NC}"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# 复制应用到临时目录
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# 创建Applications文件夹的符号链接
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# 创建DMG
echo -e "${YELLOW}创建DMG文件...${NC}"
hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_PATH"

# 检查DMG是否创建成功
if [ -f "$DMG_PATH" ]; then
    echo -e "${GREEN}DMG创建成功: $DMG_PATH${NC}"
    
    # 显示DMG信息
    echo -e "${YELLOW}DMG文件信息:${NC}"
    ls -lh "$DMG_PATH"
    
    # 清理临时文件
    rm -rf "$TEMP_DMG_DIR"
    echo -e "${GREEN}临时文件已清理${NC}"
    
    echo -e "${GREEN}✅ AppFast Connect DMG 打包完成！${NC}"
    echo -e "${YELLOW}DMG文件位置: $DMG_PATH${NC}"
else
    echo -e "${RED}错误: DMG创建失败${NC}"
    exit 1
fi
