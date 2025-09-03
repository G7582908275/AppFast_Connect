#!/bin/bash

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <版本号>"
    echo "示例: $0 1.0.0"
    exit 1
fi

VERSION=$1

# 验证版本号格式
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "错误: 版本号格式不正确，请使用 x.y.z 格式"
    echo "示例: 1.0.0, 2.1.3"
    exit 1
fi

echo "准备创建版本 v$VERSION..."

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo "警告: 有未提交的更改，请先提交或暂存更改"
    git status --short
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 创建标签
echo "创建标签 v$VERSION..."
git tag "v$VERSION"

# 推送标签
echo "推送标签到远程仓库..."
git push origin "v$VERSION"

echo "完成! 标签 v$VERSION 已创建并推送"
echo "GitHub Actions 将自动开始构建和发布流程"
echo "您可以在 GitHub 的 Actions 页面查看构建进度"
echo "构建完成后，Release 文件将自动上传到 Releases 页面"
