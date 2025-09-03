#!/bin/bash

echo "检查Linux构建依赖..."

# 检查基本构建工具
echo "检查基本构建工具..."
which clang || echo "❌ clang 未安装"
which cmake || echo "❌ cmake 未安装"
which ninja || echo "❌ ninja 未安装"
which pkg-config || echo "❌ pkg-config 未安装"

# 检查GTK开发库
echo "检查GTK开发库..."
pkg-config --exists gtk+-3.0 && echo "✅ GTK+ 3.0 已安装" || echo "❌ GTK+ 3.0 未安装"

# 检查libsecret开发库
echo "检查libsecret开发库..."
pkg-config --exists libsecret-1 && echo "✅ libsecret-1 已安装" || echo "❌ libsecret-1 未安装"

# 检查其他依赖
echo "检查其他依赖..."
pkg-config --exists sqlite3 && echo "✅ SQLite3 已安装" || echo "❌ SQLite3 未安装"

echo "依赖检查完成！"
