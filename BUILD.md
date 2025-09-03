# AppFast Connect - 构建说明

## 系统要求

- **Flutter**: 3.35.2 或更高版本
- **Dart SDK**: 3.8.0 或更高版本
- **支持的平台**: Windows x64, macOS x64/arm64, Linux x64

## 概述

本项目使用Flutter开发，支持多平台构建。在构建过程中，会自动复制对应平台的sing-box内核文件到`assets/libs/core`目录。

## 支持的平台

- **Windows**: x64
- **macOS**: x64, arm64  
- **Linux**: x64

## 构建前准备

### 0. 检查环境兼容性

在开始构建前，请确保您的Flutter环境满足要求：

```bash
# 检查Flutter版本兼容性
./scripts/check_flutter_compatibility.sh

# 检查构建配置
./scripts/check_build_config.sh
```

### 1. 自动复制内核文件

在构建前，系统会自动复制对应平台的sing-box内核文件：

```bash
# Linux/macOS
./scripts/copy_kernel.sh

# Windows
scripts\copy_kernel.bat
```

### 2. 手动复制内核文件

如果需要手动复制，可以使用以下命令：

```bash
# 复制对应平台的内核文件到assets/libs/core
cp sing-box/appfast-singbox_<platform>_<arch> assets/libs/core
```

## 本地构建

### 构建所有平台

```bash
# 复制内核文件
./scripts/copy_kernel.sh

# 构建应用
flutter build windows --release
flutter build macos --release  
flutter build linux --release
```

### 构建特定平台

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## GitHub Actions 自动构建

项目配置了GitHub Actions工作流，会在以下情况触发自动构建：

1. **推送标签**: 当推送以`v`开头的标签时（如`v1.0.0`）
2. **手动触发**: 在GitHub Actions页面手动触发

### 构建流程

1. 自动检测平台和架构
2. 复制对应平台的sing-box内核文件
3. 构建Flutter应用
4. 打包为发布格式
5. 上传构建产物
6. 创建GitHub Release（仅在有标签时）

### 构建产物

- **Windows**: `AppFast_Connect_v1.0.0_windows_x64.zip`
- **macOS**: `AppFast_Connect_v1.0.0_macos_x64.zip`, `AppFast_Connect_v1.0.0_macos_arm64.zip`
- **Linux**: `AppFast_Connect_v1.0.0_linux_x64.tar.gz`

### GitHub Release

构建完成后，所有平台的发行版文件会自动上传到GitHub Release中，用户可以直接从Release页面下载对应平台的安装包。

## 如何创建Release

### 1. 推送标签触发自动构建

```bash
# 使用脚本创建Release（推荐）
./scripts/create_release.sh 1.0.0

# 或手动创建并推送标签
git tag v1.0.0
git push origin v1.0.0
```

### 2. 手动触发构建

在GitHub仓库的Actions页面，可以手动触发构建工作流。

### 3. Release文件

构建完成后，Release文件会自动上传到GitHub Release页面，包含：
- 所有平台的安装包
- 版本说明
- 更新日志

sing-box内核文件位于`sing-box/`目录：

- `appfast-singbox_windows_amd64.exe` - Windows x64
- `appfast-singbox_darwin_amd64` - macOS x64
- `appfast-singbox_darwin_arm64` - macOS arm64
- `appfast-singbox_linux_amd64` - Linux x64

## 注意事项

1. 确保在构建前内核文件已正确复制到`assets/libs/core/`目录
2. Linux和macOS的内核文件需要执行权限
3. 构建产物会自动包含对应平台的内核文件
4. 发布时请确保所有平台的构建都成功完成
