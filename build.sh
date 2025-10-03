#!/bin/bash
# AppFast Connect macOS 构建和签名脚本
#
# 使用方法:
# 1. 自动签名构建（推荐）:
#    # 脚本会自动检测并使用系统Keychain中已安装的证书
#    ./build.sh
#
# 2. 手动签名构建:
#    export APPLE_ID="your-apple-id@example.com"
#    export APPLE_PASSWORD="your-app-specific-password"
#    # 可选: 手动指定证书（优先级高于自动检测）
#    export SIGNING_IDENTITY="Developer ID Application: Your Name (XXXXXXXXXX)"
#
# 3. 安装证书到系统:
#    ./build.sh install-certificates
#
# 证书管理:
# - 优先使用系统Keychain中已安装的证书
# - CSR目录作为证书安装源
# - 自动选择最佳证书（Developer ID Application > Distribution > Development）

# 清理临时目录
rm -fr /tmp/appfast_connect

# 检查代码签名配置
echo "检查代码签名配置..."

# 定义证书目录
CSR_DIR="$(dirname "$0")/CSR"
echo "证书目录: $CSR_DIR"

# 检查CSR目录是否存在
if [ ! -d "$CSR_DIR" ]; then
    echo "创建证书目录: $CSR_DIR"
    mkdir -p "$CSR_DIR"
fi

# 扫描CSR目录中的证书文件
echo "扫描证书文件..."
CERT_FILES=$(find "$CSR_DIR" -name "*.cer" -o -name "*.p12" -o -name "*.mobileprovision" -o -name "*.crt" 2>/dev/null)

# 自动检测系统已安装的代码签名身份
echo "检测系统已安装的代码签名身份..."
INSTALLED_IDENTITIES=$(security find-identity -v -p codesigning 2>/dev/null | grep -E "(Application|Distribution)" | head -5)

if [ ! -z "$INSTALLED_IDENTITIES" ]; then
    echo "发现以下已安装的代码签名身份:"
    echo "$INSTALLED_IDENTITIES"
    echo ""
    
    # 如果没有手动设置SIGNING_IDENTITY，自动选择最佳证书
    if [ -z "$SIGNING_IDENTITY" ]; then
        echo "自动选择代码签名身份..."
        
        # 优先选择Developer ID Application证书（用于App Store外分发）
        DEV_ID_APP=$(echo "$INSTALLED_IDENTITIES" | grep "Developer ID Application" | head -1)
        if [ ! -z "$DEV_ID_APP" ]; then
            # 提取证书身份
            IDENTITY_NAME=$(echo "$DEV_ID_APP" | sed 's/.*"\([^"]*\)".*/\1/')
            export SIGNING_IDENTITY="$IDENTITY_NAME"
            echo "✓ 自动选择: Developer ID Application - $IDENTITY_NAME"
        else
            # 其次选择Distribution证书
            DIST_CERT=$(echo "$INSTALLED_IDENTITIES" | grep -i "distribution" | head -1)
            if [ ! -z "$DIST_CERT" ]; then
                IDENTITY_NAME=$(echo "$DIST_CERT" | sed 's/.*"\([^"]*\)".*/\1/')
                export SIGNING_IDENTITY="$IDENTITY_NAME"
                echo "✓ 自动选择: Distribution证书 - $IDENTITY_NAME"
            else
                # 最后选择任何可用的证书
                ANY_CERT=$(echo "$INSTALLED_IDENTITIES" | head -1)
                if [ ! -z "$ANY_CERT" ]; then
                    IDENTITY_NAME=$(echo "$ANY_CERT" | sed 's/.*"\([^"]*\)".*/\1/')
                    export SIGNING_IDENTITY="$IDENTITY_NAME"
                    echo "✓ 自动选择: $IDENTITY_NAME"
                fi
            fi
        fi
        
        echo ""
        echo "当前使用的签名身份: $SIGNING_IDENTITY"
        
        # 验证证书有效性
        echo "验证证书有效性..."
        CERT_VALID=$(security find-certificate -c "$SIGNING_IDENTITY" -p | openssl x509 -checkend 0 -subject 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "✓ 证书有效且未过期"
        else
            echo "⚠️  证书可能已过期或无效"
        fi
        
    else
        echo "使用手动设置的签名身份: $SIGNING_IDENTITY"
        
        # 验证手动设置的证书是否存在
        CERT_EXISTS=$(security find-certificate -c "$SIGNING_IDENTITY" 2>/dev/null)
        if [ -z "$CERT_EXISTS" ]; then
            echo "⚠️  警告: 指定的证书 '$SIGNING_IDENTITY' 在系统中未找到"
            echo "请确保证书已正确安装到Keychain"
        fi
    fi
else
    echo "⚠️  未发现已安装的代码签名身份"
    
    # 检查CSR目录作为备选
    if [ ! -z "$CERT_FILES" ]; then
        echo ""
        echo "在CSR目录中发现证书文件，可以安装到系统:"
        echo "$CERT_FILES"
        echo ""
        echo "请先安装证书:"
        echo "  ./build.sh install-certificates"
    else
        echo "请确保已安装代码签名证书到系统Keychain中"
        echo "或者将证书文件放在CSR目录中"
    fi
fi

echo ""

# 检查是否有开发者账户配置
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_PASSWORD" ]; then
    echo "警告: 未设置 APPLE_ID 或 APPLE_PASSWORD 环境变量"
    echo "如果需要签名，请设置以下环境变量:"
    echo "export APPLE_ID=\"your-apple-id@example.com\""
    echo "export APPLE_PASSWORD=\"your-app-specific-password\""
    echo "export SIGNING_IDENTITY=\"Developer ID Application: Your Name (XXXXXXXXXX)\""
fi

# Build the app with code signing if configured
echo "开始构建应用..."
flutter clean

# 构建应用（根据是否有签名配置决定构建参数）
if [ ! -z "$SIGNING_IDENTITY" ]; then
    echo "使用代码签名构建..."
    flutter build macos --release --dart-define=SIGNING_IDENTITY="$SIGNING_IDENTITY"
else
    echo "构建无签名版本..."
    flutter build macos --release
fi

# Compress the DMG
APP_PATH="build/macos/Build/Products/Release/Appfast Connect.app"


# 判断当前环境并设置对应的输出文件名
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    OUTPUT_DMG="AppFast_Connect_macos_arm64.dmg"
elif [ "$ARCH" = "x86_64" ]; then
    OUTPUT_DMG="AppFast_Connect_macos_amd64.dmg"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

echo "构建平台: $ARCH"
echo "输出文件: $OUTPUT_DMG"


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

# 如果已签名，需要对DMG进行公证或额外签名处理
if [ ! -z "$SIGNING_IDENTITY" ]; then
    echo "应用已签名，准备创建签名DMG..."
    
    # 创建无签名DMG
    UNSIGNED_DMG="${OUTPUT_DMG%.dmg}_unsigned.dmg"
    hdiutil create -volname "AppFast Connect" -srcfolder "$TEMP_DMG_DIR" -ov -format UDCO "$UNSIGNED_DMG"
    
    # 签名DMG
    echo "对DMG进行代码签名..."
    codesign --sign "$SIGNING_IDENTITY" --verbose "$UNSIGNED_DMG"
    
    # 移动为最终文件
    mv "$UNSIGNED_DMG" "$OUTPUT_DMG"
    
    # 验证签名
    echo "验证DMG签名..."
    codesign --verify --verbose "$OUTPUT_DMG"
    spctl --assess --verbose "$OUTPUT_DMG"
else
    echo "创建无签名DMG..."
    hdiutil create -volname "AppFast Connect" -srcfolder "$TEMP_DMG_DIR" -ov -format UDCO "$OUTPUT_DMG"
fi

# 显示压缩结果
if [ -f "$OUTPUT_DMG" ]; then
    ORIGINAL_SIZE=$(du -h "$APP_PATH" | cut -f1)
    DMG_SIZE=$(du -h "$OUTPUT_DMG" | cut -f1)
    echo "压缩完成!"
    echo "原始应用大小: $ORIGINAL_SIZE"
    echo "DMG文件大小: $DMG_SIZE"
    
    # 如果设置了Apple ID，尝试进行公证
    if [ ! -z "$APPLE_ID" ] && [ ! -z "$APPLE_PASSWORD" ] && [ ! -z "$SIGNING_IDENTITY" ]; then
        echo "开始Apple公验证..."
        echo "注意: 公证过程可能需要几分钟时间..."
        
        # 使用altool进行公证
        xcrun altool --notarize-app \
            --primary-bundle-id "com.widewired.AppFastConnect" \
            --username "$APPLE_ID" \
            --password "$APPLE_PASSWORD" \
            --file "$OUTPUT_DMG" \
            --output-format xml
        
        if [ $? -eq 0 ]; then
            echo "公证提交成功! 请检查Apple开发者中心确认公证状态."
            echo "完成公证后，可以使用以下命令封装到DMG:"
            echo "xcrun stapler staple \"$OUTPUT_DMG\""
        else
            echo "公证提交失败!"
        fi
    else
        echo "跳过公验证 (未设置 Apple ID 或密码)"
    fi
    
else
    echo "DMG创建失败"
    exit 1
fi

# 证书安装功能
install_certificates() {
    echo "证书安装模式..."
    CSR_DIR="$(dirname "$0")/CSR"
    
    if [ ! -d "$CSR_DIR" ]; then
        echo "错误: CSR目录不存在: $CSR_DIR"
        exit 1
    fi
    
    KEYCHAIN=$(security default-keychain | cut -d'"' -f2)
    echo "目标Keychain: $KEYCHAIN"
    echo ""
    
    # 安装.cer证书文件
    CER_FILES=$(find "$CSR_DIR" -name "*.cer" -o -name "*.crt")
    if [ ! -z "$CER_FILES" ]; then
        echo "安装CER证书文件..."
        while IFS= read -r cert_file; do
            if [ -f "$cert_file" ]; then
                echo "安装: $cert_file"
                security import "$cert_file" -k "$KEYCHAIN" -T /usr/bin/codesign
                if [ $? -eq 0 ]; then
                    echo "✓ 安装成功"
                else
                    echo "✗ 安装失败"
                fi
            fi
        done <<< "$CER_FILES"
    fi
    
    # 安装.p12证书文件
    P12_FILES=$(find "$CSR_DIR" -name "*.p12")
    if [ ! -z "$P12_FILES" ]; then
        echo ""
        echo "安装P12证书文件(需要输入密码)..."
        while IFS= read -r cert_file; do
            if [ -f "$cert_file" ]; then
                echo "安装: $cert_file"
                security import "$cert_file" -k "$KEYCHAIN" -T /usr/bin/codesign
                if [ $? -eq 0 ]; then
                    echo "✓ 安装成功"
                else
                    echo "✗ 安装失败"
                fi
            fi
        done <<< "$P12_FILES"
    fi
    
    # 安装mobileprovision文件
    PROVISION_FILES=$(find "$CSR_DIR" -name "*.mobileprovision")
    if [ ! -z "$PROVISION_FILES" ]; then
        echo ""
        echo "安装配置文件..."
        while IFS= read -r prov_file; do
            if [ -f "$prov_file" ]; then
                echo "安装: $prov_file"
                PROVISION_PROFILE_NAME=$(security cms -D -i "$prov_file" 2>/dev/null | python3 -c "import sys, plistlib; print(plistlib.load(sys.stdin.buffer)['Name'])" 2>/dev/null)
                OUTPUT_PATH="$HOME/Library/MobileDevice/Provisioning Profiles/${PROVISION_PROFILE_NAME}.mobileprovision"
                mkdir -p "$(dirname "$OUTPUT_PATH")"
                cp "$prov_file" "$OUTPUT_PATH"
                if [ $? -eq 0 ]; then
                    echo "✓ 安装成功到: $OUTPUT_PATH"
                else
                    echo "✗ 安装失败"
                fi
            fi
        done <<< "$PROVISION_FILES"
    fi
    
    echo ""
    echo "证书安装完成!"
    echo ""
    echo "已安装的代码签名身份:"
    security find-identity -v -p codesigning | grep -E "(Application|Distribution)"
    echo ""
    echo "✅ 现在可以运行签名构建:"
    echo "   ./build.sh"
    echo ""
    echo "可选: 设置Apple ID用于公证发布:"
    echo "   export APPLE_ID=\"your-apple-id@example.com\""
    echo "   export APPLE_PASSWORD=\"your-app-specific-password\""
}

# 检查第一个参数是否为install-certificates
if [ "$1" = "install-certificates" ]; then
    install_certificates
    exit 0
fi