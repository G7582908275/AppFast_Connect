# Windows构建指南 - 解决LNK1327错误

## 问题描述

在Windows系统上构建Flutter应用时遇到以下错误：
```
LINK : fatal error LNK1327: failure during running mt.exe
```

这通常是由于Windows manifest文件配置问题导致的。

## 解决方案

### 1. 修改Manifest文件

我们已经将manifest文件中的权限级别从`requireAdministrator`改为`asInvoker`：

```xml
<requestedExecutionLevel level="asInvoker" uiAccess="false"/>
```

这样可以避免构建时的权限问题，同时仍然允许应用在运行时请求管理员权限。

### 2. 构建步骤

在Windows系统上执行以下命令：

```bash
# 1. 清理构建缓存
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 构建Windows应用
flutter build windows --release
```

### 3. 如果仍然遇到问题

#### 方案A: 完全移除Manifest权限声明
如果构建仍然失败，可以临时移除权限声明：

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
    </windowsSettings>
  </application>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <!-- Windows 10 and Windows 11 -->
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
    </application>
  </compatibility>
</assembly>
```

#### 方案B: 使用Debug模式构建
```bash
flutter build windows --debug
```

#### 方案C: 检查Visual Studio工具链
确保安装了正确的Visual Studio工具链：
- Visual Studio 2019或2022
- Windows 10 SDK
- C++ CMake tools

### 4. 运行时权限处理

即使manifest文件使用`asInvoker`，我们的代码仍然会在运行时检查管理员权限：

1. **权限检查**: 应用启动时检查管理员权限
2. **用户提示**: 如果权限不足，显示友好的提示信息
3. **手动提升**: 用户可以通过右键菜单以管理员身份运行

### 5. 验证构建

构建成功后，可以验证应用：

```bash
# 运行构建的应用
cd build/windows/runner/Release
./appfast_connect.exe
```

### 6. 分发说明

对于最终用户：
1. 应用可以正常安装和运行
2. 当需要VPN连接时，会提示用户以管理员身份运行
3. 用户可以通过右键菜单选择"以管理员身份运行"

## 技术说明

### Manifest权限级别说明

- **asInvoker**: 以当前用户权限运行（默认）
- **highestAvailable**: 请求可用的最高权限
- **requireAdministrator**: 要求管理员权限（可能导致构建问题）

### 为什么使用asInvoker

1. **构建兼容性**: 避免构建时的权限问题
2. **用户友好**: 应用可以正常安装和启动
3. **运行时检查**: 在需要时动态检查权限
4. **灵活性**: 用户可以选择是否以管理员身份运行

## 故障排除

### 常见问题

**Q: 构建仍然失败怎么办？**
A: 尝试方案A，完全移除manifest中的权限声明。

**Q: 应用无法连接VPN怎么办？**
A: 确保以管理员身份运行应用。

**Q: 如何确认应用是否以管理员身份运行？**
A: 在任务管理器中查看进程，应该显示"管理员"标签。

### 联系支持

如果问题仍然存在，请提供：
1. 完整的构建日志
2. Windows版本信息
3. Visual Studio版本信息
4. Flutter版本信息
