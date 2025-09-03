#!/bin/bash

echo "=== Flutter版本兼容性检查 ==="
echo

# 检查Flutter版本
echo "1. 检查Flutter版本："
FLUTTER_VERSION=$(flutter --version | grep "Flutter" | head -1 | awk '{print $2}')
echo "Flutter版本: $FLUTTER_VERSION"

# 检查Dart版本
echo "2. 检查Dart版本："
DART_VERSION=$(flutter --version | grep "Dart" | head -1 | awk '{print $4}' | sed 's/(build //' | sed 's/)//')
echo "Dart版本: $DART_VERSION"

# 检查版本兼容性
echo "3. 版本兼容性检查："

# 检查Flutter版本是否满足要求
if [[ "$FLUTTER_VERSION" == 3.24* ]] || [[ "$FLUTTER_VERSION" == 3.25* ]] || [[ "$FLUTTER_VERSION" == 3.26* ]] || [[ "$FLUTTER_VERSION" == 3.27* ]] || [[ "$FLUTTER_VERSION" == 3.28* ]] || [[ "$FLUTTER_VERSION" == 3.29* ]] || [[ "$FLUTTER_VERSION" == 3.30* ]] || [[ "$FLUTTER_VERSION" == 3.31* ]] || [[ "$FLUTTER_VERSION" == 3.32* ]] || [[ "$FLUTTER_VERSION" == 3.33* ]] || [[ "$FLUTTER_VERSION" == 3.34* ]] || [[ "$FLUTTER_VERSION" == 3.35* ]] || [[ "$FLUTTER_VERSION" == 3.36* ]]; then
    echo "✓ Flutter版本兼容 (需要 >= 3.24.0)"
else
    echo "✗ Flutter版本不兼容 (需要 >= 3.24.0)"
fi

# 检查Dart版本是否满足要求
if [[ "$DART_VERSION" == 3.5* ]] || [[ "$DART_VERSION" == 3.6* ]] || [[ "$DART_VERSION" == 3.7* ]] || [[ "$DART_VERSION" == 3.8* ]] || [[ "$DART_VERSION" == 3.9* ]] || [[ "$DART_VERSION" == 3.10* ]]; then
    echo "✓ Dart版本兼容 (需要 >= 3.5.0)"
else
    echo "✗ Dart版本不兼容 (需要 >= 3.5.0)"
fi

echo
echo "4. 依赖检查："
flutter pub get > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ 依赖解析成功"
else
    echo "✗ 依赖解析失败"
    echo "请运行 'flutter pub get' 查看详细错误信息"
fi

echo
echo "=== 检查完成 ==="
