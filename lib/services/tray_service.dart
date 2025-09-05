import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'vpn_service.dart';

class TrayService {
  static bool _isInitialized = false;
  static bool _isWindowVisible = true;
  static final _trayListener = _TrayListener();

  /// 获取图标路径
  static Future<String> _getIconPath() async {
    if (Platform.isWindows) {
      try {
        // 尝试获取当前工作目录
        final currentDir = Directory.current.path;
        debugPrint('当前工作目录: $currentDir');
        
        // 尝试多种可能的路径
        final possiblePaths = [
          'data/flutter_assets/assets/icons/app_icon.ico',  // Windows Flutter assets路径
          'assets/icons/app_icon.ico',
          './assets/icons/app_icon.ico',
          '$currentDir/assets/icons/app_icon.ico',
          '$currentDir/app_icon.ico',
          'app_icon.ico',
          'resources/app_icon.ico',
          '$currentDir/resources/app_icon.ico',
        ];
        
        for (final path in possiblePaths) {
          try {
            final file = File(path);
            if (await file.exists()) {
              final absolutePath = file.absolute.path;
              debugPrint('找到Windows图标文件: $absolutePath');
              return absolutePath;
            } else {
              debugPrint('文件不存在: $path');
            }
          } catch (e) {
            debugPrint('检查路径失败: $path - $e');
          }
        }
        
        // 如果都找不到，尝试从资源目录复制
        debugPrint('尝试从资源目录复制图标文件...');
        final resourcePath = await _copyIconFromResources();
        if (resourcePath != null) {
          return resourcePath;
        }
        
        debugPrint('未找到Windows图标文件，使用默认路径');
        return 'data/flutter_assets/assets/icons/app_icon.ico';
      } catch (e) {
        debugPrint('获取Windows图标路径时发生错误: $e');
        return 'data/flutter_assets/assets/icons/app_icon.ico';
      }
    } else {
      return 'assets/icons/app_icon.png';
    }
  }

  /// 从资源目录复制图标文件
  static Future<String?> _copyIconFromResources() async {
    try {
      // 获取临时目录
      final tempDir = Directory.systemTemp;
      final iconDir = Directory('${tempDir.path}/appfast_connect');
      
      if (!await iconDir.exists()) {
        await iconDir.create(recursive: true);
      }
      
      final iconPath = '${iconDir.path}/app_icon.ico';
      final iconFile = File(iconPath);
      
      // 如果文件已存在，直接返回
      if (await iconFile.exists()) {
        debugPrint('使用已存在的图标文件: $iconPath');
        return iconPath;
      }
      
      // 尝试从assets复制
      try {
        final bytes = await _loadAssetBytes('assets/icons/app_icon.ico');
        await iconFile.writeAsBytes(bytes);
        debugPrint('图标文件已复制到: $iconPath');
        return iconPath;
      } catch (e) {
        debugPrint('从assets复制图标文件失败: $e');
        return null;
      }
    } catch (e) {
      debugPrint('复制图标文件失败: $e');
      return null;
    }
  }

  /// 加载资源文件字节
  static Future<Uint8List> _loadAssetBytes(String assetPath) async {
    try {
      // 使用rootBundle加载资源文件
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('加载资源文件失败: $e');
      // 如果无法加载资源文件，返回一个简单的ICO文件头
      return _createSimpleIcoBytes();
    }
  }

  /// 创建一个简单的ICO文件字节数组
  static Uint8List _createSimpleIcoBytes() {
    // 创建一个16x16的简单ICO文件
    final List<int> icoBytes = [
      0x00, 0x00, // 保留字段
      0x01, 0x00, // 图标类型 (1 = ICO)
      0x01, 0x00, // 图标数量
      0x10,       // 宽度 (16)
      0x10,       // 高度 (16)
      0x00,       // 颜色数
      0x00,       // 保留字段
      0x01, 0x00, // 颜色平面数
      0x20, 0x00, // 每像素位数
      0x00, 0x01, 0x00, 0x00, // 图像数据大小
      0x16, 0x00, 0x00, 0x00, // 图像数据偏移
    ];
    
    // 添加简单的16x16像素数据 (32位RGBA)
    for (int i = 0; i < 16 * 16; i++) {
      icoBytes.addAll([0x00, 0x00, 0xFF, 0xFF]); // 蓝色像素
    }
    
    return Uint8List.fromList(icoBytes);
  }

  /// 初始化托盘服务
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('开始初始化托盘服务...');
      debugPrint('当前平台: ${Platform.operatingSystem}');
      
      if (Platform.isWindows) {
        // Windows 平台特殊处理
        await _initializeWindowsTray();
      } else {
        // 其他平台使用标准方法
        await _initializeStandardTray();
      }
      
      _isInitialized = true;
      debugPrint('托盘服务初始化完成');
    } catch (e) {
      debugPrint('托盘服务初始化失败: $e');
      debugPrint('错误堆栈: ${e.toString()}');
      // 即使托盘初始化失败，也不应该阻止应用启动
      _isInitialized = true;
    }
  }

  /// Windows 平台托盘初始化
  static Future<void> _initializeWindowsTray() async {
    debugPrint('开始Windows托盘初始化...');
    
    try {
      // 首先尝试设置托盘菜单
      await _setupTrayMenu();
      debugPrint('Windows托盘菜单设置完成');

      // 监听托盘事件
      trayManager.addListener(_trayListener);
      debugPrint('Windows托盘事件监听器已添加');
      
      // 尝试显示托盘图标
      await show();
      debugPrint('Windows托盘图标已显示');
      
      // 验证托盘是否真的显示成功
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('Windows托盘初始化验证完成');
      
    } catch (e) {
      debugPrint('Windows托盘初始化失败: $e');
      debugPrint('错误详情: ${e.toString()}');
      
      // 尝试备用方案：使用简单的图标
      try {
        debugPrint('尝试使用备用图标方案...');
        await _setupTrayMenu();
        trayManager.addListener(_trayListener);
        
        // 使用默认图标路径
        await trayManager.setIcon('data/flutter_assets/assets/icons/app_icon.ico');
        debugPrint('备用图标方案成功');
      } catch (e2) {
        debugPrint('备用图标方案也失败: $e2');
        // 即使失败也继续，不阻止应用启动
      }
    }
  }

  /// 标准平台托盘初始化
  static Future<void> _initializeStandardTray() async {
    debugPrint('开始标准托盘初始化...');
    
    try {
      // 设置托盘菜单
      await _setupTrayMenu();
      debugPrint('托盘菜单设置完成');

      // 监听托盘事件
      trayManager.addListener(_trayListener);
      debugPrint('托盘事件监听器已添加');
      
      // 确保托盘图标显示
      await show();
      debugPrint('托盘图标已显示');
    } catch (e) {
      debugPrint('标准托盘初始化失败: $e');
      // 即使失败也继续，不阻止应用启动
    }
  }

  /// 设置托盘菜单
  static Future<void> _setupTrayMenu() async {
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: '显示窗口',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: '退出应用',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  /// 显示托盘图标
  static Future<void> show() async {
    try {
      final iconPath = await _getIconPath();
      debugPrint('设置托盘图标: $iconPath');
      await trayManager.setIcon(iconPath);
      debugPrint('托盘图标设置成功');
    } catch (e) {
      debugPrint('设置托盘图标失败: $e');
    }
  }

  /// 隐藏托盘图标
  static Future<void> hide() async {
    await trayManager.destroy();
  }

  /// 显示窗口
  static Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
    // 在任务栏显示
    await windowManager.setSkipTaskbar(false);
    _isWindowVisible = true;
    debugPrint('窗口已显示，并在任务栏显示');
  }

  /// 隐藏窗口
  static Future<void> hideWindow() async {
    try {
      // 隐藏窗口
      await windowManager.hide();
      // 从任务栏隐藏
      await windowManager.setSkipTaskbar(true);
      _isWindowVisible = false;
      
      // 确保托盘图标显示（只有在托盘服务已初始化时）
      if (_isInitialized) {
        await show();
        debugPrint('窗口已隐藏到托盘，托盘图标已显示');
      } else {
        debugPrint('窗口已隐藏，但托盘服务未初始化');
      }
    } catch (e) {
      debugPrint('隐藏窗口时发生错误: $e');
    }
  }

  /// 检查窗口是否可见
  static bool get isWindowVisible => _isWindowVisible;

  /// 退出应用
  static Future<void> quit() async {
    debugPrint('开始退出应用...');
    
    // 检查是否处于连接状态
    if (VPNService.isConnected) {
      debugPrint('检测到VPN连接状态，正在断开连接...');
      try {
        final success = await VPNService.disconnect();
        if (success) {
          debugPrint('VPN连接已断开，core进程已清理');
        } else {
          debugPrint('VPN断开连接失败，但继续退出应用');
        }
      } catch (e) {
        debugPrint('VPN断开连接时发生错误: $e');
      }
    } else {
      debugPrint('未检测到VPN连接状态');
    }
    
    // 销毁托盘图标
    await trayManager.destroy();
    debugPrint('托盘图标已销毁');
    
    // 退出应用
    exit(0);
  }
}

/// 托盘事件监听器
class _TrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    // 点击托盘图标时显示窗口
    try {
      TrayService.showWindow();
    } catch (e) {
      debugPrint('显示窗口失败: $e');
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    // 右键点击托盘图标时显示上下文菜单
    try {
      trayManager.popUpContextMenu();
    } catch (e) {
      debugPrint('显示托盘菜单失败: $e');
      // 如果菜单显示失败，至少显示窗口
      try {
        TrayService.showWindow();
      } catch (e2) {
        debugPrint('显示窗口也失败: $e2');
      }
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    try {
      switch (menuItem.key) {
        case 'show_window':
          TrayService.showWindow();
          break;
        case 'quit':
          TrayService.quit();
          break;
        default:
          debugPrint('未知的菜单项: ${menuItem.key}');
      }
    } catch (e) {
      debugPrint('处理托盘菜单点击失败: $e');
    }
  }
}
