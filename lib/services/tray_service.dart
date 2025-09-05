import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'vpn_service.dart';
import 'process_service.dart';

class TrayService {
  static bool _isInitialized = false;
  static bool _isWindowVisible = true;
  static final _trayListener = _TrayListener();
  static bool _isProcessingClick = false;

  /// 获取图标路径
  static Future<String> _getIconPath() async {
    if (Platform.isWindows) {
      try {
        final appDir = File(Platform.resolvedExecutable).parent.path;
        final possiblePaths = [
          'data/flutter_assets/assets/icons/app_icon.ico',
          'assets/icons/app_icon.ico',
          '$appDir/assets/icons/app_icon.ico',
          '$appDir/app_icon.ico',
        ];
        
        for (final path in possiblePaths) {
          if (await File(path).exists()) {
            return File(path).absolute.path;
          }
        }
        
        // 尝试从资源复制
        final resourcePath = await _copyIconFromResources();
        return resourcePath ?? 'data/flutter_assets/assets/icons/app_icon.ico';
      } catch (e) {
        return 'data/flutter_assets/assets/icons/app_icon.ico';
      }
    }
    return 'assets/icons/app_icon.png';
  }

  /// 从资源目录复制图标文件
  static Future<String?> _copyIconFromResources() async {
    try {
      final tempDir = Directory.systemTemp;
      final iconDir = Directory('${tempDir.path}/appfast_connect');
      
      if (!await iconDir.exists()) {
        await iconDir.create(recursive: true);
      }
      
      final iconPath = '${iconDir.path}/app_icon.ico';
      final iconFile = File(iconPath);
      
      if (await iconFile.exists()) {
        return iconPath;
      }
      
      try {
        final bytes = await _loadAssetBytes('assets/icons/app_icon.ico');
        await iconFile.writeAsBytes(bytes);
        return iconPath;
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 加载资源文件字节
  static Future<Uint8List> _loadAssetBytes(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      return _createSimpleIcoBytes();
    }
  }

  /// 创建一个简单的ICO文件字节数组
  static Uint8List _createSimpleIcoBytes() {
    final List<int> icoBytes = [
      0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x10, 0x10, 0x00, 0x00, 0x01, 0x00,
      0x20, 0x00, 0x00, 0x01, 0x00, 0x00, 0x16, 0x00, 0x00, 0x00,
    ];
    
    for (int i = 0; i < 16 * 16; i++) {
      icoBytes.addAll([0x00, 0x00, 0xFF, 0xFF]);
    }
    
    return Uint8List.fromList(icoBytes);
  }

  /// 初始化托盘服务
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _setupTrayMenu();
      trayManager.addListener(_trayListener);
      await show();
      _isInitialized = true;
    } catch (e) {
      debugPrint('托盘服务初始化失败: $e');
      _isInitialized = true;
    }
  }

  /// 设置托盘菜单
  static Future<void> _setupTrayMenu() async {
    final menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: '显示窗口'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: '退出应用'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  /// 显示托盘图标
  static Future<void> show() async {
    try {
      final iconPath = await _getIconPath();
      await trayManager.setIcon(iconPath);
    } catch (e) {
      try {
        await trayManager.setIcon('data/flutter_assets/assets/icons/app_icon.ico');
      } catch (e2) {
        debugPrint('设置托盘图标失败: $e2');
      }
    }
  }

  /// 隐藏托盘图标
  static Future<void> hide() async {
    await trayManager.destroy();
  }

  /// 显示窗口
  static Future<void> showWindow() async {
    try {
      await windowManager.setSkipTaskbar(false);
      await windowManager.show();
      await windowManager.focus();
      _isWindowVisible = true;
      
      if (_isInitialized) {
        await show();
      }
    } catch (e) {
      debugPrint('显示窗口失败: $e');
      _isWindowVisible = false;
      rethrow;
    }
  }

  /// 隐藏窗口
  static Future<void> hideWindow() async {
    try {
      if (_isInitialized) {
        await show();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      await windowManager.setSkipTaskbar(true);
      await windowManager.hide();
      _isWindowVisible = false;
      
      if (_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 300));
        await show();
      }
    } catch (e) {
      debugPrint('隐藏窗口失败: $e');
      _isWindowVisible = true;
      try {
        await windowManager.setSkipTaskbar(false);
        await windowManager.show();
      } catch (e2) {
        debugPrint('恢复窗口显示失败: $e2');
      }
    }
  }

  /// 检查窗口是否可见
  static bool get isWindowVisible => _isWindowVisible;

  /// 重置初始化状态
  static void resetInitialization() {
    _isInitialized = false;
  }

  /// 恢复托盘图标
  static Future<void> recoverTrayIcon() async {
    try {
      _isInitialized = false;
      await initialize();
    } catch (e) {
      debugPrint('恢复托盘图标失败: $e');
    }
  }

  /// 退出应用
  static Future<void> quit() async {
    if (VPNService.isConnected) {
      try {
        await VPNService.disconnect();
      } catch (e) {
        debugPrint('VPN断开连接失败: $e');
      }
    }
    
    // 清理进程锁文件
    try {
      await ProcessService.removeLockFile();
    } catch (e) {
      debugPrint('清理进程锁文件失败: $e');
    }
    
    await trayManager.destroy();
    exit(0);
  }
}

/// 托盘事件监听器
class _TrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    if (TrayService._isProcessingClick) return;
    
    try {
      TrayService._isProcessingClick = true;
      
      if (TrayService._isWindowVisible) {
        TrayService.hideWindow().then((_) {
          TrayService._isProcessingClick = false;
        }).catchError((e) {
          debugPrint('隐藏窗口失败: $e');
          TrayService._isProcessingClick = false;
        });
      } else {
        TrayService.showWindow().then((_) {
          TrayService._isProcessingClick = false;
        }).catchError((e) {
          debugPrint('显示窗口失败: $e');
          TrayService._isProcessingClick = false;
        });
      }
    } catch (e) {
      debugPrint('处理托盘点击失败: $e');
      TrayService._isProcessingClick = false;
      try {
        TrayService.showWindow();
      } catch (e2) {
        debugPrint('备用显示窗口失败: $e2');
      }
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    try {
      trayManager.popUpContextMenu();
    } catch (e) {
      debugPrint('显示托盘菜单失败: $e');
      try {
        TrayService.showWindow();
      } catch (e2) {
        debugPrint('显示窗口失败: $e2');
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
          debugPrint('未知菜单项: ${menuItem.key}');
      }
    } catch (e) {
      debugPrint('处理菜单点击失败: $e');
    }
  }
}