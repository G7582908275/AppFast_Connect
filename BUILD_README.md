# AppFast Connect 构建说明

## 应用程序信息
- **应用名称**: AppFast Connect
- **描述**: VPN连接管理器
- **版本**: 1.0.0

## 构建步骤

### 1. 开发环境构建
```bash
# 清理并获取依赖
flutter clean
flutter pub get

# 运行开发版本
flutter run -d macos
```

### 2. 发布版本构建
```bash
# 构建发布版本
flutter build macos --release
```

### 3. DMG打包
```bash
# 使用自动化脚本打包DMG
./build_dmg.sh
```

## DMG文件内容
生成的DMG文件将包含：
- `AppFast Connect.app` - 主应用程序
- `Applications` - 指向系统Applications文件夹的快捷方式

## 文件结构
```
build/
├── AppFast_Connect.dmg          # 最终DMG文件
├── macos/
│   └── Build/
│       └── Products/
│           └── Release/
│               └── AppFast Connect.app  # 应用程序包
└── temp_dmg/                    # 临时DMG构建目录
```

## 注意事项
1. 确保macOS开发环境已正确配置
2. 应用程序需要网络扩展权限用于VPN功能
3. DMG文件会自动包含Applications文件夹的快捷方式
4. 构建过程会自动清理临时文件

## 故障排除
如果构建失败，请检查：
- Flutter环境是否正确安装
- Xcode命令行工具是否已安装
- 是否有足够的磁盘空间
- 网络连接是否正常（用于获取依赖）

