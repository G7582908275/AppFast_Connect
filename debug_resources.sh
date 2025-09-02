#!/bin/bash

# 测试脚本：验证macOS应用中的资源文件
# 用于诊断VPN连接失败问题

echo "=== AppFast Connect 资源文件诊断工具 ==="
echo ""

# 检查应用是否存在
APP_PATH="build/macos/Build/Products/Release/appfast_connect.app"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用不存在: $APP_PATH"
    echo "请先运行: flutter build macos --release"
    exit 1
fi

echo "✅ 应用存在: $APP_PATH"
echo ""

# 检查应用包内容
echo "=== 应用包内容 ==="
ls -la "$APP_PATH/Contents/"
echo ""

# 检查资源文件
echo "=== 资源文件检查 ==="
RESOURCES_PATH="$APP_PATH/Contents/Resources"
if [ -d "$RESOURCES_PATH" ]; then
    echo "✅ 资源目录存在: $RESOURCES_PATH"
    echo "资源文件列表:"
    ls -la "$RESOURCES_PATH"
    echo ""
    
    # 检查Flutter资源
    FLUTTER_ASSETS="$RESOURCES_PATH/flutter_assets"
    if [ -d "$FLUTTER_ASSETS" ]; then
        echo "✅ Flutter资源目录存在"
        echo "Flutter资源内容:"
        find "$FLUTTER_ASSETS" -type f -name "*.dmg" -o -name "*darwin*" | head -10
        echo ""
    else
        echo "❌ Flutter资源目录不存在"
    fi
    
    # 检查assets目录
    ASSETS_PATH="$FLUTTER_ASSETS/assets"
    if [ -d "$ASSETS_PATH" ]; then
        echo "✅ Assets目录存在"
        echo "Assets内容:"
        find "$ASSETS_PATH" -type f | head -10
        echo ""
        
        # 检查libs目录
        LIBS_PATH="$ASSETS_PATH/libs"
        if [ -d "$LIBS_PATH" ]; then
            echo "✅ Libs目录存在"
            echo "Libs内容:"
            ls -la "$LIBS_PATH"
            echo ""
            
            # 检查darwin目录
            DARWIN_PATH="$LIBS_PATH/darwin"
            if [ -d "$DARWIN_PATH" ]; then
                echo "✅ Darwin目录存在"
                echo "Darwin文件:"
                ls -la "$DARWIN_PATH"
                echo ""
                
                # 检查可执行文件
                EXEC_FILES=$(find "$DARWIN_PATH" -name "*darwin*" -type f)
                if [ -n "$EXEC_FILES" ]; then
                    echo "✅ 找到可执行文件:"
                    for file in $EXEC_FILES; do
                        echo "  - $file ($(stat -f%z "$file") bytes)"
                        if [ -x "$file" ]; then
                            echo "    ✅ 有执行权限"
                        else
                            echo "    ❌ 无执行权限"
                        fi
                    done
                else
                    echo "❌ 未找到可执行文件"
                fi
            else
                echo "❌ Darwin目录不存在"
            fi
        else
            echo "❌ Libs目录不存在"
        fi
    else
        echo "❌ Assets目录不存在"
    fi
else
    echo "❌ 资源目录不存在"
fi

echo ""
echo "=== 诊断完成 ==="
echo ""
echo "如果资源文件存在但VPN仍然连接失败，可能的原因："
echo "1. 权限问题 - 应用需要管理员权限"
echo "2. 网络扩展权限 - 需要在系统偏好设置中授权"
echo "3. 防火墙阻止 - 检查系统防火墙设置"
echo "4. 可执行文件损坏 - 尝试重新构建应用"
echo ""
echo "建议的解决步骤："
echo "1. 运行应用并查看控制台输出"
echo "2. 检查系统日志: Console.app -> 搜索应用名称"
echo "3. 尝试手动运行可执行文件测试"
echo "4. 检查网络扩展权限设置"
