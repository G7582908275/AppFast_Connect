import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService {
  static bool _isInitialized = false;
  static bool _isWindowVisible = true;
  static final _trayListener = _TrayListener();

  /// 初始化托盘服务
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化托盘管理器
      await trayManager.setIcon(
        Platform.isWindows 
          ? 'assets/icons/app_icon.ico'
          : 'assets/icons/app_icon.png'
      );

      // 设置托盘菜单
      await _setupTrayMenu();

      // 监听托盘事件
      trayManager.addListener(_trayListener);

      _isInitialized = true;
      debugPrint('托盘服务初始化完成');
    } catch (e) {
      debugPrint('托盘服务初始化失败: $e');
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
    if (!_isInitialized) await initialize();
    await trayManager.setIcon(
      Platform.isWindows 
        ? 'assets/icons/app_icon.ico'
        : 'assets/icons/app_icon.png'
    );
  }

  /// 隐藏托盘图标
  static Future<void> hide() async {
    await trayManager.destroy();
  }

  /// 显示窗口
  static Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
    _isWindowVisible = true;
  }

  /// 隐藏窗口
  static Future<void> hideWindow() async {
    await windowManager.hide();
    _isWindowVisible = false;
  }

  /// 检查窗口是否可见
  static bool get isWindowVisible => _isWindowVisible;

  /// 退出应用
  static Future<void> quit() async {
    await trayManager.destroy();
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
