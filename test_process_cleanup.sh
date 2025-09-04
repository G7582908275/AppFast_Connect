#!/bin/bash

echo "=== 测试进程清理功能 ==="
echo "当前时间: $(date)"

echo ""
echo "1. 检查当前是否有appfast相关进程:"
ps aux | grep -E "(appfast|core.*appfast)" | grep -v grep

echo ""
echo "2. 等待5秒后再次检查:"
sleep 5
ps aux | grep -E "(appfast|core.*appfast)" | grep -v grep

echo ""
echo "3. 如果有进程残留，手动清理:"
if pgrep -f "appfast_connect/core" > /dev/null; then
    echo "发现appfast_connect/core进程，正在清理..."
    sudo pkill -f "appfast_connect/core"
    sleep 2
    sudo pkill -9 -f "appfast_connect/core"
    echo "清理完成"
else
    echo "没有发现appfast相关进程"
fi

echo ""
echo "4. 最终检查:"
ps aux | grep -E "(appfast|core.*appfast)" | grep -v grep

echo ""
echo "=== 测试完成 ==="
