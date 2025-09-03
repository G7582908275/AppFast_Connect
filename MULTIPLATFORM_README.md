# AppFast Connect - 多平台支持

## 概述

AppFast Connect 现在支持多个平台，包括 macOS、Windows 和 Linux。每个平台都有相应的 sing-box 二进制文件，在打包时会被重命名为 `core`。

## 支持的平台

### macOS
- **架构**: arm64 (Apple Silicon) / x64 (Intel)
- **文件**: `core` (无扩展名)
- **权限**: 需要 sudo 权限
- **工作目录**: `/tmp/appfast_connect`

### Windows
- **架构**: arm64 / x64
- **文件**: `core.exe`
- **权限**: 需要管理员权限
- **工作目录**: `%TEMP%\appfast_connect`

### Linux
- **架构**: arm64 / x64
- **文件**: `core` (无扩展名)
- **权限**: 需要 root 或 sudo 权限
- **工作目录**: `/tmp/appfast_connect`

## 核心功能

### 1. 平台检测 (`PlatformUtils`)

```dart
// 平台检测
PlatformUtils.isMacOS
PlatformUtils.isWindows
PlatformUtils.isLinux

// 架构检测
PlatformUtils.architecture // 返回 'arm64' 或 'x64'

// 文件名获取
PlatformUtils.libraryFileName // 返回平台特定的文件名
```

### 2. 资源文件管理

```dart
// 获取可执行文件路径
final path = await PlatformUtils.getExecutablePath();

// 验证可执行文件
final isValid = await PlatformUtils.validateExecutableFile();

// 加载资源文件
final bytes = await PlatformUtils.loadAssetBytes('assets/libs/core');
```

### 3. 权限管理 (`PermissionUtils`)

```dart
// 检查管理员权限
final isAdmin = await PermissionUtils.isRunningAsAdmin();

// 检查网络权限
final hasNetwork = await PermissionUtils.hasNetworkExtensionPermission();

// 请求权限
final granted = await PermissionUtils.requestSudoPrivileges();
```

### 4. VPN 服务 (`VPNService`)

```dart
// 连接 VPN
final result = await VPNService.connectWithError();

// 检查连接状态
final isConnected = await VPNService.checkConnectionStatus();

// 断开连接
await VPNService.disconnect();
```

## 平台特定配置

### macOS
- 使用 `sudo` 执行命令
- 配置文件下载 URL: `mac` 或 `mac-safe`
- 网络接口检测: `ifconfig` 查找 `utun*`

### Windows
- 直接执行可执行文件
- 配置文件下载 URL: `win`
- 网络接口检测: `netsh` 查找 `TAP-Windows Adapter` 或 `VPN`

### Linux
- 直接执行可执行文件（可能需要 sudo）
- 配置文件下载 URL: `linux`
- 网络接口检测: `ip link` 查找 `tun*` 或 `tap*`

## 环境变量

### macOS
```dart
{
  'HOME': '/tmp/appfast_connect',
  'TMPDIR': '/tmp/appfast_connect',
}
```

### Windows
```dart
{
  'TEMP': '%TEMP%',
  'TMP': '%TEMP%',
}
```

### Linux
```dart
{
  'HOME': '/tmp/appfast_connect',
  'TMPDIR': '/tmp/appfast_connect',
}
```

## 错误处理

每个平台都有相应的错误处理机制：

1. **权限不足**: 提示用户以管理员身份运行
2. **文件不存在**: 自动从 assets 释放文件
3. **网络接口检测失败**: 使用 API 检查作为备选方案
4. **进程异常退出**: 记录日志并尝试重新连接

## 测试

使用 `PlatformTest` 类进行功能测试：

```dart
// 运行所有测试
await PlatformTest.runAllTests();

// 测试资源文件加载
await PlatformTest.testAssetLoading();
```

## 注意事项

1. **打包时**: 确保将对应平台的 sing-box 二进制文件重命名为 `core`
2. **权限**: Windows 和 Linux 用户需要以管理员身份运行应用
3. **防火墙**: 某些平台可能需要配置防火墙规则
4. **依赖**: Linux 平台可能需要安装额外的网络工具包

## 日志

所有平台操作都会记录详细的日志，包括：
- 平台检测结果
- 权限检查状态
- 文件操作过程
- VPN 连接状态
- 错误信息

日志文件位置：
- macOS: `/tmp/appfast_connect/logs/`
- Windows: `%TEMP%\appfast_connect\logs\`
- Linux: `/tmp/appfast_connect/logs/`
