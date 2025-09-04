import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'vpn_service.dart';

class TrayService {
  static bool _isInitialized = false;
  static bool _isWindowVisible = true;
  static final _trayListener = _TrayListener();

  /// 获取图标路径
  static Future<String> _getIconPath() async {
    if (Platform.isWindows) {
      // Windows 平台尝试多种路径
      final paths = [
        'assets/icons/app_icon.ico',
        './assets/icons/app_icon.ico',
        'app_icon.ico',
      ];
      
      for (final path in paths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            debugPrint('找到Windows图标文件: $path');
            return path;
          }
        } catch (e) {
          debugPrint('检查路径失败: $path - $e');
        }
      }
      
      debugPrint('未找到Windows图标文件，使用默认路径');
      return 'assets/icons/app_icon.ico';
    } else {
      return 'assets/icons/app_icon.png';
    }
  }

  /// 初始化托盘服务
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('开始初始化托盘服务...');
      debugPrint('当前平台: ${Platform.operatingSystem}');
      
      // 获取图标路径
      final iconPath = await _getIconPath();
      debugPrint('使用图标路径: $iconPath');
      
      // 初始化托盘管理器
      await trayManager.setIcon(iconPath);
      debugPrint('托盘图标设置完成');

      // 设置托盘菜单
      await _setupTrayMenu();
      debugPrint('托盘菜单设置完成');

      // 监听托盘事件
      trayManager.addListener(_trayListener);
      debugPrint('托盘事件监听器已添加');

      _isInitialized = true;
      debugPrint('托盘服务初始化完成');
      
      // 确保托盘图标显示
      await show();
      debugPrint('托盘图标已显示');
    } catch (e) {
      debugPrint('托盘服务初始化失败: $e');
      debugPrint('错误堆栈: ${e.toString()}');
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
    if (!_isInitialized) {
      debugPrint('托盘服务未初始化，开始初始化...');
      await initialize();
    }
    
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
    // 确保托盘图标显示
    await show();
    // 隐藏窗口
    await windowManager.hide();
    // 从任务栏隐藏
    await windowManager.setSkipTaskbar(true);
    _isWindowVisible = false;
    debugPrint('窗口已隐藏到托盘，并从任务栏隐藏');
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
    TrayService.showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    // 右键点击托盘图标时显示上下文菜单
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        TrayService.showWindow();
        break;
      case 'quit':
        TrayService.quit();
        break;
    }
  }
}
