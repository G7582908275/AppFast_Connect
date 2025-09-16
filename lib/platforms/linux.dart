import '../utils/logger.dart';
import '../services/vpn_service.dart';
import '../services/tray_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Linux 平台初始化器
class LinuxPlatform {
  /// Linux 特定的初始化流程
  static Future<void> initializePlatform() async {
    await Logger.logInfo('=== Linux 应用启动 ===');
    
    // 执行通用初始化
    await _initializeCommon();
    
    // 初始化窗口管理器
    await _initializeWindowManager();
    
    // 设置窗口属性
    await _setCommonWindowProperties();
    
    // 初始化托盘服务
    await _initializeTrayService();
    
    // 记录启动完成
    await Logger.logInfo('Linux 应用启动完成');
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
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await windowManager.ensureInitialized();
      await windowManager.waitUntilReadyToShow();
    } catch (e) {
      await Logger.logError('窗口管理器初始化失败', e);
    }
  }

  /// 设置通用窗口属性
  static Future<void> _setCommonWindowProperties() async {
    try {
      await _setWindowSize();
      await _setWindowConstraints();
      await _setWindowBasicProperties();
      await _setWindowDisplayProperties();
      await windowManager.center();
      await windowManager.setPreventClose(true);
      await windowManager.show();
    } catch (e) {
      await Logger.logError('窗口属性设置失败', e);
    }
  }

  /// 设置窗口大小
  static Future<void> _setWindowSize() async {
    try {
      await windowManager.setSize(const Size(400, 630));
    } catch (e) {
      // 忽略错误，继续执行
    }
  }

  /// 设置窗口尺寸限制
  static Future<void> _setWindowConstraints() async {
    try {
      await windowManager.setResizable(false);
      await windowManager.setMinimumSize(const Size(400, 630));
      await windowManager.setMaximumSize(const Size(400, 630));
    } catch (e) {
      // 忽略错误，继续执行
    }
  }

  /// 设置窗口基本属性
  static Future<void> _setWindowBasicProperties() async {
    try {
      await windowManager.setTitle('');
      await windowManager.setClosable(true);
    } catch (e) {
      // 忽略错误，继续执行
    }
  }

  /// 设置窗口显示属性
  static Future<void> _setWindowDisplayProperties() async {
    try {
      await windowManager.setSkipTaskbar(false);
      await windowManager.setAlwaysOnTop(false);
    } catch (e) {
      // 忽略错误，继续执行
    }
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

/// Linux 平台入口函数
Future<void> initializePlatform() async {
  await LinuxPlatform.initializePlatform();
}
