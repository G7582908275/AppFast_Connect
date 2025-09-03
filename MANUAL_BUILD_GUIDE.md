# GitHub Actions 手动构建说明

## 功能概述

现在您可以通过GitHub Actions手动选择要编译的平台和架构，而不需要构建所有平台。

## 使用方法

1. 进入GitHub仓库的Actions页面
2. 选择"Build and Release"工作流
3. 点击"Run workflow"按钮
4. 在弹出窗口中配置以下参数：

### 平台选择 (platform)
- **all**: 构建所有平台（Windows、macOS、Linux）
- **windows**: 仅构建Windows版本
- **macos**: 仅构建macOS版本  
- **linux**: 仅构建Linux版本

### 架构选择 (architecture)
- **all**: 构建所有架构（x64、arm64）
- **x64**: 仅构建x64架构
- **arm64**: 仅构建arm64架构

## 使用场景

### 场景1：测试特定平台
如果您只想测试Windows版本，可以：
- 平台：选择 `windows`
- 架构：选择 `all`

### 场景2：快速构建特定架构
如果您只需要x64版本，可以：
- 平台：选择 `all`
- 架构：选择 `x64`

### 场景3：精确构建
如果您只需要Windows的arm64版本，可以：
- 平台：选择 `windows`
- 架构：选择 `arm64`

## 构建产物

构建完成后，产物会自动上传到GitHub Actions的Artifacts中，您可以：
1. 在Actions页面查看构建结果
2. 下载对应的构建产物
3. 查看构建日志了解详细信息

## 注意事项

- 手动构建不会创建GitHub Release，产物会保存在Artifacts中
- 只有通过tag推送触发的构建才会创建Release
- 构建时间会根据选择的平台数量相应减少
