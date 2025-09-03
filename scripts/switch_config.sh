#!/bin/bash

echo "=== 切换Flutter配置 ==="
echo

if [ "$1" = "backup" ]; then
    echo "切换到备用配置（兼容Dart 3.5.0）..."
    cp pubspec.yaml.backup pubspec.yaml
    echo "✓ 已切换到备用配置"
    echo "flutter_lints版本: ^5.0.0"
    echo "Dart SDK要求: >=3.5.0 <4.0.0"
elif [ "$1" = "main" ]; then
    echo "切换到主配置（需要Dart 3.8.0+）..."
    # 这里需要手动恢复主配置，因为我们已经修改了原文件
    echo "请手动恢复pubspec.yaml到主配置："
    echo "- flutter_lints版本: ^6.0.0"
    echo "- Dart SDK要求: >=3.8.0 <4.0.0"
else
    echo "用法: $0 [backup|main]"
    echo "  backup - 切换到备用配置（兼容Dart 3.5.0）"
    echo "  main   - 切换到主配置（需要Dart 3.8.0+）"
    echo
    echo "当前配置："
    echo "flutter_lints版本: $(grep 'flutter_lints:' pubspec.yaml | head -1)"
    echo "Dart SDK要求: $(grep 'sdk:' pubspec.yaml | head -1)"
fi

echo
echo "运行 'flutter pub get' 来更新依赖"
