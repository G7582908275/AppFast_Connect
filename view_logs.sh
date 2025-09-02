#!/bin/bash

# 日志查看脚本
# 用于查看AppFast Connect的日志文件

echo "=== AppFast Connect 日志查看工具 ==="
echo ""

# 主要日志目录
LOG_DIR="/tmp/appfast_connect/logs"

if [ ! -d "$LOG_DIR" ]; then
    echo "❌ 日志目录不存在: $LOG_DIR"
    echo ""
    echo "可能的原因："
    echo "1. 应用还没有运行过"
    echo "2. 应用没有创建日志文件"
    echo "3. /tmp目录权限不足"
    exit 1
fi

echo "✅ 找到日志目录: $LOG_DIR"
echo ""

# 列出所有日志文件
echo "📁 日志文件列表:"
ls -la "$LOG_DIR"/*.log 2>/dev/null || echo "没有找到.log文件"

echo ""

# 查找最新的日志文件
LATEST_LOG=$(find "$LOG_DIR" -name "*.log" -type f -exec ls -t {} + | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "❌ 没有找到日志文件"
    exit 1
fi

echo "📄 最新日志文件: $LATEST_LOG"
echo "文件大小: $(du -h "$LATEST_LOG" | cut -f1)"
echo "最后修改: $(stat -f "%Sm" "$LATEST_LOG")"
echo ""

# 显示日志内容
echo "📋 日志内容 (最后50行):"
echo "=========================================="
tail -50 "$LATEST_LOG"
echo "=========================================="

echo ""
echo "💡 提示："
echo "- 要查看完整日志，运行: cat \"$LATEST_LOG\""
echo "- 要实时监控日志，运行: tail -f \"$LATEST_LOG\""
echo "- 要搜索特定内容，运行: grep \"关键词\" \"$LATEST_LOG\""
echo ""
echo "🔧 如果应用在Applications文件夹中运行失败，请检查："
echo "1. 应用是否有必要的权限"
echo "2. 系统偏好设置 -> 安全性与隐私 -> 通用"
echo "3. 是否允许来自未识别开发者的应用"
echo "4. 网络扩展权限设置"
