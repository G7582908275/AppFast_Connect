import '../utils/logger.dart';
import '../services/vpn_service.dart';
import '../services/tray_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// macOS 平台初始化器
class MacOSPlatform {
  /// macOS 特定的初始化流程
  static Future<void> initializePlatform() async {
    try {
      await Logger.logInfo('=== macOS 应用启动 ===');
      
      // 执行通用初始化
      await _initializeCommon();
          
      // 初始化窗口管理器
      await _initializeWindowManager();
      
      // 设置窗口属性
      await _setCommonWindowProperties();
      
      // 初始化托盘服务
      await _initializeTrayService();
      
      // 记录启动完成
      await Logger.logInfo('macOS 应用启动完成');
    } catch (e) {
      await Logger.logError('macOS平台初始化失败', e);
      rethrow;
    }
  }

  /// 通用初始化步骤
  static Future<void> _initializeCommon() async {
    // 初始化日志系统
    await Logger.initialize();

    // 初始化VPN服务
    VPNService.initialize();
  }

  /// 初始化窗口管理器
  static Future<void> _initializeWindowManager() async {
    await windowManager.ensureInitialized();
  }

  /// 设置通用窗口属性
  static Future<void> _setCommonWindowProperties() async {
    await windowManager.setSize(const Size(400, 630));
    await windowManager.setResizable(false);
    await windowManager.setMinimumSize(const Size(400, 630));
    await windowManager.setMaximumSize(const Size(400, 630));
    await windowManager.setTitle('');
    await windowManager.setClosable(true);
    await windowManager.show();
  }

  /// 初始化托盘服务
  static Future<void> _initializeTrayService() async {
    try {
      await TrayService.initialize();
      await Logger.logInfo('托盘服务初始化完成');
    } catch (e) {
      await Logger.logError('托盘服务初始化失败，但应用将继续运行', e);
    }
  }
}

/// macOS 平台入口函数
Future<void> initializePlatform() async {
  await MacOSPlatform.initializePlatform();
}
