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
      print('Windows平台初始化开始...');
      await Logger.logInfo('=== Windows 应用启动 ===');
      
      // 执行通用初始化
      print('开始执行通用初始化...');
      await _initializeCommon();
      print('通用初始化完成');
      
      // 初始化窗口管理器
      print('开始初始化窗口管理器...');
      await _initializeWindowManager();
      print('窗口管理器初始化完成');
      
      // 设置窗口属性
      print('开始设置窗口属性...');
      await _setCommonWindowProperties();
      print('窗口属性设置完成');
      
      // 初始化托盘服务
      print('开始初始化托盘服务...');
      await _initializeTrayService();
      print('托盘服务初始化完成');
      
      // 记录启动完成
      await Logger.logInfo('Windows 应用启动完成');
      print('Windows平台初始化完成');
    } catch (e) {
      print('Windows平台初始化失败: $e');
      await Logger.logError('Windows平台初始化失败', e);
      rethrow;
    }
  }

  /// 通用初始化步骤
  static Future<void> _initializeCommon() async {
    try {
      print('开始初始化日志系统...');
      // 初始化日志系统
      await Logger.initialize();
      print('日志系统初始化完成');

      print('开始初始化VPN服务...');
      // 初始化VPN服务
      VPNService.initialize();
      print('VPN服务初始化完成');
    } catch (e) {
      print('通用初始化失败: $e');
      await Logger.logError('通用初始化失败', e);
      rethrow;
    }
  }

  /// 初始化窗口管理器
  static Future<void> _initializeWindowManager() async {
    try {
      print('开始初始化窗口管理器...');
      await windowManager.ensureInitialized();
      print('窗口管理器初始化成功');
    } catch (e) {
      print('窗口管理器初始化失败: $e');
      await Logger.logError('窗口管理器初始化失败', e);
      rethrow;
    }
  }

  /// 设置通用窗口属性
  static Future<void> _setCommonWindowProperties() async {
    try {
      print('开始设置窗口属性...');
      await windowManager.setSize(const Size(400, 630));
      await windowManager.setResizable(false);
      await windowManager.setMinimumSize(const Size(400, 630));
      await windowManager.setMaximumSize(const Size(400, 630));
      await windowManager.setTitle('');
      await windowManager.setClosable(true);
      
      // 添加关键配置
      await windowManager.setSkipTaskbar(false);  // 确保在任务栏显示
      await windowManager.setAlwaysOnTop(false);  // 不总是置顶
      await windowManager.center();               // 居中显示
      
      await windowManager.show();
      print('窗口属性设置成功');
    } catch (e) {
      print('窗口属性设置失败: $e');
      await Logger.logError('窗口属性设置失败', e);
      rethrow;
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

/// Windows 平台入口函数
Future<void> initializePlatform() async {
  await WindowsPlatform.initializePlatform();
}
