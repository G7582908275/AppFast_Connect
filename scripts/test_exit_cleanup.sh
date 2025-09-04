#!/bin/bash

# 测试应用退出时的进程清理机制
echo "=== 测试应用退出时的进程清理机制 ==="
echo ""

# 1. 检查当前是否有相关进程
echo "1. 检查当前进程状态..."
CURRENT_PIDS=$(pgrep -f 'appfast_connect.*core' 2>/dev/null)
if [[ -n "$CURRENT_PIDS" ]]; then
    echo "当前有相关进程在运行:"
    echo "$CURRENT_PIDS"
    echo ""
    echo "请先清理现有进程，然后重新测试"
    exit 1
else
    echo "✓ 当前没有相关进程在运行"
fi

echo ""

# 2. 模拟启动core进程
echo "2. 模拟启动core进程..."
if [[ -f "sing-box/core" ]]; then
    echo "启动core进程..."
    ./sing-box/core > /dev/null 2>&1 &
    CORE_PID=$!
    echo "Core进程已启动，PID: $CORE_PID"
    sleep 2
    
    # 验证进程是否启动
    if ps -p $CORE_PID > /dev/null 2>&1; then
        echo "✓ Core进程启动成功"
    else
        echo "✗ Core进程启动失败"
        exit 1
    fi
else
    echo "未找到core可执行文件，跳过测试"
    exit 0
fi

echo ""

# 3. 测试应用退出时的清理机制
echo "3. 测试应用退出时的清理机制..."
echo "现在请关闭应用，然后检查进程是否被正确清理"
echo ""

# 等待用户关闭应用
echo "请关闭应用，然后按回车键继续..."
read -r

echo ""

# 4. 检查进程是否被清理
echo "4. 检查进程清理结果..."
REMAINING_PIDS=$(pgrep -f 'appfast_connect.*core' 2>/dev/null)

if [[ -n "$REMAINING_PIDS" ]]; then
    echo "❌ 仍有相关进程在运行:"
    echo "$REMAINING_PIDS"
    echo ""
    echo "应用退出时的清理机制可能存在问题"
    echo "建议检查以下方面："
    echo "1. 应用是否正确调用了disconnect()方法"
    echo "2. 进程清理服务是否正确执行"
    echo "3. 是否有权限问题"
    echo ""
    echo "可以使用清理脚本手动清理:"
    echo "sudo ./scripts/cleanup_processes.sh"
else
    echo "✓ 所有相关进程已被正确清理"
    echo "应用退出时的清理机制工作正常"
fi

echo ""
echo "=== 测试完成 ==="
