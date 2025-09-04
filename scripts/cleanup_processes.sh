#!/bin/bash

# AppFast Connect 进程清理脚本
# 用于手动清理遗留的core进程

echo "=== AppFast Connect 进程清理脚本 ==="
echo "当前时间: $(date)"
echo ""

# 检查操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="Windows"
else
    OS="Unknown"
fi

echo "检测到操作系统: $OS"
echo ""

# 函数：清理进程
cleanup_processes() {
    echo "开始清理AppFast Connect相关进程..."
    
    if [[ "$OS" == "macOS" || "$OS" == "Linux" ]]; then
        # Unix系统清理
        
        # 1. 查找包含appfast_connect路径的core进程
        echo "查找AppFast Connect相关进程..."
        PIDS=$(pgrep -f 'appfast_connect.*core' 2>/dev/null)
        
        if [[ -n "$PIDS" ]]; then
            echo "发现以下进程:"
            echo "$PIDS"
            echo ""
            
            # 2. 逐个结束进程
            for PID in $PIDS; do
                echo "正在结束进程 PID: $PID"
                
                # 验证进程是否真的属于AppFast Connect
                PROCESS_INFO=$(ps -p $PID -o args= 2>/dev/null)
                if [[ "$PROCESS_INFO" == *"appfast_connect"* ]]; then
                    kill -9 $PID 2>/dev/null
                    if [[ $? -eq 0 ]]; then
                        echo "✓ 成功结束进程 PID: $PID"
                    else
                        echo "✗ 结束进程 PID: $PID 失败"
                    fi
                else
                    echo "⚠ 跳过不属于AppFast Connect的进程 PID: $PID"
                fi
            done
        else
            echo "没有发现AppFast Connect相关进程"
        fi
        
        # 3. 额外检查：使用ps命令查找
        echo ""
        echo "额外检查：使用ps命令查找..."
        PS_PIDS=$(ps aux | grep -E "appfast_connect.*core" | grep -v grep | awk '{print $2}')
        
        if [[ -n "$PS_PIDS" ]]; then
            echo "通过ps命令发现以下进程:"
            echo "$PS_PIDS"
            echo ""
            
            for PID in $PS_PIDS; do
                echo "正在结束进程 PID: $PID"
                kill -9 $PID 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "✓ 成功结束进程 PID: $PID"
                else
                    echo "✗ 结束进程 PID: $PID 失败"
                fi
            done
        else
            echo "通过ps命令没有发现额外进程"
        fi
        
    elif [[ "$OS" == "Windows" ]]; then
        # Windows系统清理
        echo "Windows系统清理..."
        
        # 使用tasklist查找core.exe进程
        TASK_LIST=$(tasklist /FI "IMAGENAME eq core.exe" /FO CSV 2>/dev/null)
        
        if [[ "$TASK_LIST" == *"core.exe"* ]]; then
            echo "发现core.exe进程，正在结束..."
            taskkill /F /IM core.exe 2>/dev/null
            if [[ $? -eq 0 ]]; then
                echo "✓ 成功结束core.exe进程"
            else
                echo "✗ 结束core.exe进程失败"
            fi
        else
            echo "没有发现core.exe进程"
        fi
    fi
}

# 函数：验证清理结果
verify_cleanup() {
    echo ""
    echo "=== 验证清理结果 ==="
    
    if [[ "$OS" == "macOS" || "$OS" == "Linux" ]]; then
        # 检查是否还有相关进程
        REMAINING_PIDS=$(pgrep -f 'appfast_connect.*core' 2>/dev/null)
        
        if [[ -n "$REMAINING_PIDS" ]]; then
            echo "⚠ 仍有AppFast Connect相关进程在运行:"
            echo "$REMAINING_PIDS"
            echo ""
            echo "尝试强制清理..."
            
            # 强制清理所有core进程（谨慎使用）
            pkill -9 -f 'core' 2>/dev/null
            sleep 1
            
            # 再次检查
            REMAINING_PIDS=$(pgrep -f 'appfast_connect.*core' 2>/dev/null)
            if [[ -n "$REMAINING_PIDS" ]]; then
                echo "❌ 清理失败，仍有进程在运行:"
                echo "$REMAINING_PIDS"
                return 1
            else
                echo "✓ 强制清理成功"
            fi
        else
            echo "✓ 所有AppFast Connect相关进程已清理完成"
        fi
        
    elif [[ "$OS" == "Windows" ]]; then
        # Windows验证
        TASK_LIST=$(tasklist /FI "IMAGENAME eq core.exe" /FO CSV 2>/dev/null)
        
        if [[ "$TASK_LIST" == *"core.exe"* ]]; then
            echo "❌ 仍有core.exe进程在运行"
            return 1
        else
            echo "✓ 所有core.exe进程已清理完成"
        fi
    fi
    
    return 0
}

# 函数：清理临时文件
cleanup_temp_files() {
    echo ""
    echo "=== 清理临时文件 ==="
    
    if [[ "$OS" == "macOS" || "$OS" == "Linux" ]]; then
        # 清理/tmp目录下的相关文件
        if [[ -d "/tmp/appfast_connect" ]]; then
            echo "清理 /tmp/appfast_connect 目录..."
            rm -rf /tmp/appfast_connect 2>/dev/null
            if [[ $? -eq 0 ]]; then
                echo "✓ 临时文件清理完成"
            else
                echo "⚠ 临时文件清理失败"
            fi
        else
            echo "没有发现临时文件目录"
        fi
        
    elif [[ "$OS" == "Windows" ]]; then
        # Windows临时文件清理
        TEMP_DIR="$TEMP\\appfast_connect"
        if [[ -d "$TEMP_DIR" ]]; then
            echo "清理 $TEMP_DIR 目录..."
            rmdir /s /q "$TEMP_DIR" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                echo "✓ 临时文件清理完成"
            else
                echo "⚠ 临时文件清理失败"
            fi
        else
            echo "没有发现临时文件目录"
        fi
    fi
}

# 主执行流程
main() {
    echo "开始执行进程清理..."
    echo ""
    
    # 1. 清理进程
    cleanup_processes
    
    # 2. 验证清理结果
    verify_cleanup
    CLEANUP_RESULT=$?
    
    # 3. 清理临时文件
    cleanup_temp_files
    
    echo ""
    echo "=== 清理完成 ==="
    
    if [[ $CLEANUP_RESULT -eq 0 ]]; then
        echo "✓ 进程清理成功"
        exit 0
    else
        echo "❌ 进程清理失败"
        exit 1
    fi
}

# 检查是否以root权限运行（Unix系统）
if [[ "$OS" == "macOS" || "$OS" == "Linux" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "⚠ 警告：建议以root权限运行此脚本以确保完全清理"
        echo "可以使用: sudo $0"
        echo ""
    fi
fi

# 执行主函数
main
