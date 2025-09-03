# Linux构建问题完整解决方案

## 遇到的问题

### 1. 第一个错误：缺少 libsecret-1
```
CMake Error: The following required packages were not found:
   - libsecret-1>=0.18.4
```

### 2. 第二个错误：缺少 ayatana-appindicator3
```
CMake Error: The `tray_manager` package requires ayatana-appindicator3-0.1 or appindicator3-0.1
```

## 完整解决方案

### 更新的依赖包列表
```yaml
- name: Install dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libblkid-dev liblzma-dev libsqlite3-dev libayatana-appindicator3-dev libx11-dev libxrandr-dev libxss-dev
```

### 依赖包说明
- `clang`: C/C++编译器
- `cmake`: 构建系统
- `ninja-build`: 构建工具
- `pkg-config`: 包配置工具
- `libgtk-3-dev`: GTK+ 3.0开发库
- `liblzma-dev`: LZMA压缩库
- `libsecret-1-dev`: flutter_secure_storage_linux 插件所需
- `libblkid-dev`: 文件系统相关依赖
- `libsqlite3-dev`: SQLite数据库支持
- `libayatana-appindicator3-dev`: tray_manager 插件所需（系统托盘功能）
- `libx11-dev`: X11开发库
- `libxrandr-dev`: X11 RandR扩展开发库
- `libxss-dev`: X11屏幕保护程序扩展开发库

### 其他改进
- 添加了 `flutter config --enable-linux-desktop` 步骤
- 添加了 `flutter doctor -v` 检查步骤

## 测试工具
使用 `test_linux_deps.sh` 脚本来检查所有依赖是否正确安装。

## 验证
现在可以重新运行GitHub Actions构建，Linux版本应该能够成功构建。
