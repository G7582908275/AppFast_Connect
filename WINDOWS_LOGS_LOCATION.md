# Windows日志文件位置

## 日志文件存储位置

### Windows系统
日志文件存储在用户临时目录中：
```
%TEMP%\appfast_connect\logs\
```

具体路径通常是：
- **Windows 10/11**: `C:\Users\[用户名]\AppData\Local\Temp\appfast_connect\logs\`
- **Windows 7/8**: `C:\Users\[用户名]\AppData\Local\Temp\appfast_connect\logs\`

### 日志文件命名
日志文件使用时间戳命名：
```
app_[时间戳].log
```

例如：`app_1703123456789.log`

## 如何查看日志

### 方法1：通过文件资源管理器
1. 按 `Win + R` 打开运行对话框
2. 输入 `%TEMP%` 并回车
3. 导航到 `appfast_connect\logs` 文件夹
4. 找到最新的日志文件

### 方法2：通过命令行
```cmd
# 查看临时目录
echo %TEMP%

# 列出日志文件
dir "%TEMP%\appfast_connect\logs"

# 查看最新日志文件
type "%TEMP%\appfast_connect\logs\app_*.log"
```

### 方法3：通过PowerShell
```powershell
# 查看日志目录
Get-ChildItem $env:TEMP\appfast_connect\logs

# 查看最新日志文件内容
Get-Content $env:TEMP\appfast_connect\logs\app_*.log | Select-Object -Last 50
```

## 日志内容示例
```
[2023-12-21T10:30:45.123Z] === AppFast Connect 启动 ===
[2023-12-21T10:30:45.124Z] 日志文件路径: C:\Users\用户名\AppData\Local\Temp\appfast_connect\logs\app_1703123456789.log
[2023-12-21T10:30:45.125Z] 系统信息: windows 10.0.19045
[2023-12-21T10:30:45.126Z] 应用路径: C:\path\to\app.exe
[2023-12-21T10:30:45.127Z] INFO: 尝试加载资源文件: assets/libs/core
[2023-12-21T10:30:45.128Z] ERROR: 所有加载方法都失败，无法访问assets文件: assets/libs/core
```

## 清理日志
可以通过应用内的日志查看器清理日志，或者手动删除日志目录。
