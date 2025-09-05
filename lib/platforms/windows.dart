import '../utils/logger.dart';
import '../services/vpn_service.dart';
import '../services/tray_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 平台初始化器
class WindowsPlatform {
  /// Windows 特定的初始化流程
  static Future<void> initializePlatform() async {
    try {
      await Logger.logInfo('=== Windows 应用启动 ===');
      await _initializeCommon();
      await _initializeWindowManager();
      await _setCommonWindowProperties();
      await _initializeTrayService();
      await Logger.logInfo('Windows 应用启动完成');
    } catch (e) {
      await Logger.logError('Windows平台初始化失败', e);
    }
  }

  /// 通用初始化步骤
  static Future<void> _initializeCommon() async {
    try {
      await Logger.initialize();
      VPNService.initialize();
    } catch (e) {
      await Logger.logError('通用初始化失败', e);
      rethrow;
    }
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
      await Logger.logError('托盘服务初始化失败', e);
    }
  }
}

/// Windows 平台入口函数
Future<void> initializePlatform() async {
  await WindowsPlatform.initializePlatform();
}