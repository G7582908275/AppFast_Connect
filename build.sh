#!/bin/bash
# AppFast Connect macOS 通用二进制构建和签名脚本
#
# 功能特性:
# - 构建包含 x64(Intel) 和 arm64(Apple Silicon) 双架构的通用二进制包
# - 支持代码签名和 Apple 公证
# - 自动检测和使用系统 Keychain 中的证书
# - 支持多种公证方式（API密钥、App专用密码）
#
# 使用方法:
# 1. 自动签名构建（推荐）:
#    # 脚本会自动检测并使用系统Keychain中已安装的证书
#    ./build.sh
#
# 2. 手动签名构建:
#    export APPLE_ID="your-apple-id@example.com"
#    export APPLE_PASSWORD="your-app-specific-password"
#    export TEAM_ID="L6Z7DC2D3Y"
#    # 可选: 手动指定证书（优先级高于自动检测）
#    export SIGNING_IDENTITY="Developer ID Application: Your Name (XXXXXXXXXX)"
#
# 3. 使用API密钥公证:
#    export API_KEY_FILE="AuthKey_XXXXXXXXXX.p8"
#    export API_KEY_ID="XXXXXXXXXX"
#    export API_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#    ./build.sh
#
# 4. 安装证书到系统:
#    ./build.sh install-certificates
#
# 5. 验证签名状态:
#    ./build.sh verify
#
# 证书管理:
# - 优先使用系统Keychain中已安装的证书
# - CSR目录作为证书安装源
# - 自动选择最佳证书（Developer ID Application > Distribution > Development）
#
# 公证方式:
# - 方法1: API密钥公证（推荐，需要Notarization权限）
# - 方法2: App专用密码公证（需要Apple ID网站访问）
# - 自动封装公证票据到DMG


# 环境变量配置（请根据实际情况修改）
# export APPLE_ID="your-apple-id@example.com"
# export APPLE_PASSWORD="your-app-specific-password"
# export TEAM_ID="L6Z7DC2D3Y"

# API密钥配置（可选，用于公证）
# export API_KEY_FILE="AuthKey_QZ2CNY9TNJ.p8"
# export API_KEY_ID="QZ2CNY9TNJ"
# export API_ISSUER_ID="d414c4d5-f39f-4e51-81cd-ca6b358d0a95"

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
        DEV_ID_APP=$(echo "$INSTALLED_IDENTITIES" | grep "Developer ID Application" | grep "E35B85B607621E32FF27AAEAAB8CADF00696E03B" | head -1)
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
    echo "如果需要签名和公证，请设置以下环境变量:"
    echo "export APPLE_ID=\"your-apple-id@example.com\""
    echo "export APPLE_PASSWORD=\"your-app-specific-password\""
    echo "export TEAM_ID=\"XXXXXXXXXX\"  # 可选，但推荐设置"
    echo "export SIGNING_IDENTITY=\"Developer ID Application: Your Name (XXXXXXXXXX)\""
    echo ""
    echo "重要提示:"
    echo "- 必须使用 'Developer ID Application' 类型的证书才能在其他电脑上正常运行"
    echo "- 公证是必需的，否则会出现安全提示"
fi

# Build the app with code signing if configured
echo "开始构建应用..."
flutter clean

# 构建应用（根据是否有签名配置决定构建参数）
if [ ! -z "$SIGNING_IDENTITY" ]; then
    echo "使用代码签名构建..."
    echo "签名身份: $SIGNING_IDENTITY"
    
    # 设置Flutter构建时的签名参数
    export FLUTTER_BUILD_MACOS_SIGNING_IDENTITY="$SIGNING_IDENTITY"
    
    # 构建时指定签名身份
    flutter build macos --release \
        --dart-define=SIGNING_IDENTITY="$SIGNING_IDENTITY" \
        --dart-define=CODE_SIGN_IDENTITY="$SIGNING_IDENTITY"
else
    echo "构建无签名版本..."
    flutter build macos --release
fi

# Compress the DMG
APP_PATH="build/macos/Build/Products/Release/Appfast Connect.app"


# 构建通用二进制包（支持 x64 和 arm64 双架构）
OUTPUT_DMG="AppFast_Connect_macos_universal.dmg"

echo "构建模式: 通用二进制包 (Universal Binary)"
echo "支持架构: x86_64 (Intel) + arm64 (Apple Silicon)"
echo "输出文件: $OUTPUT_DMG"


echo "开始压缩DMG..."

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "错误: 应用不存在 $APP_PATH"
    exit 1
fi

# 验证通用二进制架构
echo "验证通用二进制架构..."
BINARY_PATH="$APP_PATH/Contents/MacOS/appfast_connect"
if [ -f "$BINARY_PATH" ]; then
    ARCHITECTURES=$(lipo -info "$BINARY_PATH" 2>/dev/null)
    if echo "$ARCHITECTURES" | grep -q "arm64 x86_64"; then
        echo "✓ 通用二进制验证成功: $ARCHITECTURES"
    elif echo "$ARCHITECTURES" | grep -q "x86_64 arm64"; then
        echo "✓ 通用二进制验证成功: $ARCHITECTURES"
    else
        echo "⚠️  警告: 二进制文件可能不是通用架构"
        echo "检测到的架构: $ARCHITECTURES"
        echo "继续构建，但建议检查 Xcode 项目配置"
    fi
else
    echo "⚠️  警告: 无法找到二进制文件进行架构验证: $BINARY_PATH"
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

# 如果已签名，需要对应用和DMG进行正确的分发签名
if [ ! -z "$SIGNING_IDENTITY" ]; then
    echo "应用已签名，准备创建分发签名DMG..."
    
    # 首先对原始应用进行重新签名（确保使用正确的证书）
    echo "对原始应用进行重新签名..."
    
    # 检查是否为Developer ID证书
    if echo "$SIGNING_IDENTITY" | grep -q "Developer ID Application"; then
        echo "使用Developer ID Application证书进行分发签名..."
        
        # 对原始应用进行深度签名（包括所有内部组件）
        # 使用具体证书哈希值避免重复证书问题
        CERTIFICATE_HASH="E35B85B607621E32FF27AAEAAB8CADF00696E03B"
        codesign --force --deep --sign "$CERTIFICATE_HASH" \
            --options runtime \
            --entitlements "macos/Runner/Release.entitlements" \
            --verbose "$APP_PATH"
        
        if [ $? -eq 0 ]; then
            echo "✓ 原始应用分发签名成功"
            
            # 验证原始应用签名
            echo "验证原始应用签名..."
            codesign --verify --deep --verbose "$APP_PATH"
            spctl --assess --verbose "$APP_PATH"
        else
            echo "✗ 原始应用分发签名失败"
            exit 1
        fi
        
        # 现在对DMG中的应用进行签名
        APP_IN_DMG="$TEMP_DMG_DIR/Appfast Connect.app"
        echo "对DMG中的应用进行分发签名..."
        
        codesign --force --deep --sign "$CERTIFICATE_HASH" \
            --options runtime \
            --entitlements "macos/Runner/Release.entitlements" \
            --verbose "$APP_IN_DMG"
        
        if [ $? -eq 0 ]; then
            echo "✓ DMG中的应用分发签名成功"
            
            # 验证DMG中的应用签名
            echo "验证DMG中的应用签名..."
            codesign --verify --deep --verbose "$APP_IN_DMG"
            spctl --assess --verbose "$APP_IN_DMG"
        else
            echo "✗ DMG中的应用分发签名失败"
            exit 1
        fi
    else
        echo "警告: 使用的不是Developer ID Application证书，可能无法在其他电脑上正常运行"
        echo "当前证书: $SIGNING_IDENTITY"
        echo "建议使用 'Developer ID Application: Your Name (XXXXXXXXXX)' 类型的证书"
    fi
    
    # 创建DMG
    echo "创建DMG..."
    hdiutil create -volname "AppFast Connect" -srcfolder "$TEMP_DMG_DIR" -ov -format UDCO "$OUTPUT_DMG"
    
    # 对DMG进行签名
    echo "对DMG进行代码签名..."
    CERTIFICATE_HASH="E35B85B607621E32FF27AAEAAB8CADF00696E03B"
    codesign --sign "$CERTIFICATE_HASH" --verbose "$OUTPUT_DMG"
    
    # 验证DMG签名
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
    
    # 尝试进行公证
    echo ""
    echo "=== 开始公证流程 ==="
    
    NOTARIZATION_SUCCESS=false
    
    # 方法1: 使用API密钥公证
    if [ ! -z "$API_KEY_FILE" ] && [ ! -z "$API_KEY_ID" ] && [ ! -z "$API_ISSUER_ID" ] && [ -f "$API_KEY_FILE" ]; then
        echo "方法1: 使用API密钥进行公证..."
        echo "API密钥: $API_KEY_FILE"
        echo "Key ID: $API_KEY_ID"
        echo "Issuer ID: $API_ISSUER_ID"
        
        xcrun notarytool submit "$OUTPUT_DMG" \
            --key "$API_KEY_FILE" \
            --key-id "$API_KEY_ID" \
            --issuer "$API_ISSUER_ID" \
            --wait
        
        if [ $? -eq 0 ]; then
            echo "✓ API密钥公证成功!"
            NOTARIZATION_SUCCESS=true
        else
            echo "✗ API密钥公证失败"
        fi
    fi
    
    # 方法2: 使用App专用密码公证
    if [ "$NOTARIZATION_SUCCESS" = false ] && [ ! -z "$APPLE_ID" ] && [ ! -z "$APPLE_PASSWORD" ]; then
        echo ""
        echo "方法2: 使用App专用密码进行公证..."
        echo "Apple ID: $APPLE_ID"
        
        if [ ! -z "$TEAM_ID" ]; then
            xcrun notarytool submit "$OUTPUT_DMG" \
                --apple-id "$APPLE_ID" \
                --password "$APPLE_PASSWORD" \
                --team-id "$TEAM_ID" \
                --wait
        else
            xcrun notarytool submit "$OUTPUT_DMG" \
                --apple-id "$APPLE_ID" \
                --password "$APPLE_PASSWORD" \
                --wait
        fi
        
        if [ $? -eq 0 ]; then
            echo "✓ App专用密码公证成功!"
            NOTARIZATION_SUCCESS=true
        else
            echo "✗ App专用密码公证失败"
        fi
    fi
    
    # 封装公证票据
    if [ "$NOTARIZATION_SUCCESS" = true ]; then
        echo ""
        echo "封装公证票据到DMG..."
        xcrun stapler staple "$OUTPUT_DMG"
        
        if [ $? -eq 0 ]; then
            echo "✓ 公证票据封装成功!"
            echo "现在DMG可以在其他电脑上正常运行，不会出现安全提示"
        else
            echo "⚠️  公证票据封装失败，但公证已成功"
        fi
    else
        echo ""
        echo "⚠️  公证失败!"
        echo "应用已签名但未公证，在其他电脑上会显示安全警告"
        echo ""
        echo "解决方案:"
        echo "1. 设置正确的环境变量:"
        echo "   export APPLE_ID=\"your-apple-id@example.com\""
        echo "   export APPLE_PASSWORD=\"your-app-specific-password\""
        echo "   export TEAM_ID=\"L6Z7DC2D3Y\""
        echo ""
        echo "2. 或使用API密钥:"
        echo "   export API_KEY_FILE=\"AuthKey_XXXXXXXXXX.p8\""
        echo "   export API_KEY_ID=\"XXXXXXXXXX\""
        echo "   export API_ISSUER_ID=\"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\""
        echo ""
        echo "3. 临时分发方案:"
        echo "   用户可以通过右键点击DMG文件，选择'打开'来绕过安全警告"
    fi
    
else
    echo "DMG创建失败"
    exit 1
fi

# 自动运行签名验证
echo ""
echo "=== 签名验证报告 ==="

if [ -d "$APP_PATH" ]; then
    echo "1. 应用签名状态:"
    codesign -dv "$APP_PATH" 2>&1 | head -5
    echo ""
    
    echo "2. 应用签名验证:"
    if codesign --verify --deep --verbose "$APP_PATH" 2>/dev/null; then
        echo "✓ 应用签名验证通过"
    else
        echo "✗ 应用签名验证失败"
    fi
    echo ""
    
    echo "3. 应用安全评估:"
    if spctl --assess --verbose "$APP_PATH" 2>/dev/null; then
        echo "✓ 应用通过安全评估"
    else
        echo "⚠️  应用未通过安全评估（可能需要公证）"
    fi
    echo ""
fi

if [ -f "$OUTPUT_DMG" ]; then
    echo "4. DMG签名状态:"
    codesign -dv "$OUTPUT_DMG" 2>&1 | head -3
    echo ""
    
    echo "5. DMG签名验证:"
    if codesign --verify --verbose "$OUTPUT_DMG" 2>/dev/null; then
        echo "✓ DMG签名验证通过"
    else
        echo "✗ DMG签名验证失败"
    fi
    echo ""
    
    echo "6. DMG安全评估:"
    if spctl --assess --verbose "$OUTPUT_DMG" 2>/dev/null; then
        echo "✓ DMG通过安全评估"
    else
        echo "⚠️  DMG未通过安全评估（可能需要公证）"
    fi
    echo ""
    
    echo "7. 公证状态检查:"
    if xcrun stapler validate "$OUTPUT_DMG" 2>/dev/null; then
        echo "✓ DMG已包含公证票据"
    else
        echo "⚠️  DMG未包含公证票据或公证未完成"
    fi
fi

echo "=== 验证完成 ==="

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
    echo "   export TEAM_ID=\"XXXXXXXXXX\""
    echo ""
    echo "重要提示:"
    echo "- 必须使用 'Developer ID Application' 证书才能在其他电脑上正常运行"
    echo "- 公证是必需的，否则会出现安全提示"
    echo "- 可以在Apple开发者中心申请Developer ID证书"
}

# 验证签名状态的函数
verify_signing() {
    local app_path="$1"
    local dmg_path="$2"
    
    echo ""
    echo "=== 签名验证报告 ==="
    
    if [ -d "$app_path" ]; then
        echo "1. 应用签名状态:"
        codesign -dv "$app_path" 2>&1 | head -5
        echo ""
        
        echo "2. 应用签名验证:"
        if codesign --verify --deep --verbose "$app_path" 2>/dev/null; then
            echo "✓ 应用签名验证通过"
        else
            echo "✗ 应用签名验证失败"
        fi
        echo ""
        
        echo "3. 应用安全评估:"
        if spctl --assess --verbose "$app_path" 2>/dev/null; then
            echo "✓ 应用通过安全评估"
        else
            echo "⚠️  应用未通过安全评估（可能需要公证）"
        fi
        echo ""
    fi
    
    if [ -f "$dmg_path" ]; then
        echo "4. DMG签名状态:"
        codesign -dv "$dmg_path" 2>&1 | head -3
        echo ""
        
        echo "5. DMG签名验证:"
        if codesign --verify --verbose "$dmg_path" 2>/dev/null; then
            echo "✓ DMG签名验证通过"
        else
            echo "✗ DMG签名验证失败"
        fi
        echo ""
        
        echo "6. DMG安全评估:"
        if spctl --assess --verbose "$dmg_path" 2>/dev/null; then
            echo "✓ DMG通过安全评估"
        else
            echo "⚠️  DMG未通过安全评估（可能需要公证）"
        fi
        echo ""
        
        echo "7. 公证状态检查:"
        if xcrun stapler validate "$dmg_path" 2>/dev/null; then
            echo "✓ DMG已包含公证票据"
        else
            echo "⚠️  DMG未包含公证票据或公证未完成"
        fi
    fi
    
    echo "=== 验证完成 ==="
    echo ""
}

# 检查第一个参数是否为install-certificates
if [ "$1" = "install-certificates" ]; then
    install_certificates
    exit 0
fi

# 检查第一个参数是否为verify
if [ "$1" = "verify" ]; then
    if [ -f "$OUTPUT_DMG" ]; then
        verify_signing "$APP_PATH" "$OUTPUT_DMG"
    else
        echo "错误: 找不到DMG文件 $OUTPUT_DMG"
        echo "请先运行 ./build.sh 构建应用"
    fi
    exit 0
fi

# 检查第一个参数是否为notarize
if [ "$1" = "notarize" ]; then
    if [ ! -f "$OUTPUT_DMG" ]; then
        echo "错误: 找不到DMG文件 $OUTPUT_DMG"
        echo "请先运行 ./build.sh 构建应用"
        exit 1
    fi
    
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_PASSWORD" ]; then
        echo "错误: 未设置公证所需的环境变量"
        echo "请设置以下环境变量:"
        echo "export APPLE_ID=\"your-apple-id@example.com\""
        echo "export APPLE_PASSWORD=\"your-app-specific-password\""
        echo "export TEAM_ID=\"L6Z7DC2D3Y\""
        exit 1
    fi
    
    echo "开始对已构建的DMG进行公证..."
    echo "DMG文件: $OUTPUT_DMG"
    echo ""
    
    # 获取正确的Bundle ID
    BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "build/macos/Build/Products/Release/AppFast Connect.app/Contents/Info.plist" 2>/dev/null || echo "com.widewired.appfastConnect")
    echo "使用Bundle ID: $BUNDLE_ID"
    
    # 使用notarytool进行公证
    echo "使用notarytool进行公证..."
    if [ ! -z "$TEAM_ID" ]; then
        xcrun notarytool submit "$OUTPUT_DMG" \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_PASSWORD" \
            --team-id "$TEAM_ID" \
            --wait
    else
        xcrun notarytool submit "$OUTPUT_DMG" \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_PASSWORD" \
            --wait
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ 公证成功!"
        
        # 自动封装公证票据
        echo "封装公证票据到DMG..."
        xcrun stapler staple "$OUTPUT_DMG"
        
        if [ $? -eq 0 ]; then
            echo "✓ 公证票据封装成功!"
            echo "现在DMG可以在其他电脑上正常运行，不会出现安全提示"
            
            # 验证公证状态
            echo ""
            echo "验证公证状态..."
            if xcrun stapler validate "$OUTPUT_DMG" 2>/dev/null; then
                echo "✓ DMG已包含公证票据"
            else
                echo "⚠️  DMG未包含公证票据"
            fi
        else
            echo "⚠️  公证票据封装失败，但公证已成功"
        fi
    else
        echo "✗ 公证失败!"
        echo "请检查Apple ID、密码和Team ID是否正确"
        exit 1
    fi
    
    exit 0
fi