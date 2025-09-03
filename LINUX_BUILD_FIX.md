# Linux构建问题解决方案

## 问题描述
在GitHub Actions中构建Linux版本时遇到以下错误：
```
CMake Error: The following required packages were not found:
   - libsecret-1>=0.18.4
```

## 解决方案

### 1. 更新GitHub Actions配置
在 `.github/workflows/build.yml` 文件中的 `build-linux` 任务中添加了以下依赖包：

```yaml
- name: Install dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libblkid-dev liblzma-dev libsqlite3-dev
```

### 2. 添加的依赖包说明
- `libsecret-1-dev`: flutter_secure_storage_linux 插件所需
- `libblkid-dev`: 文件系统相关依赖
- `libsqlite3-dev`: SQLite数据库支持

### 3. 其他改进
- 添加了 `flutter config --enable-linux-desktop` 步骤
- 添加了 `flutter doctor -v` 检查步骤

## 本地测试
可以使用 `test_linux_deps.sh` 脚本来检查依赖是否正确安装：

```bash
./test_linux_deps.sh
```

## 验证修复
现在可以重新运行GitHub Actions构建，Linux版本应该能够成功构建。
