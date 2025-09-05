import 'dart:io';
import '../utils/permission_utils.dart';
import '../utils/platform_utils.dart';
import '../utils/logger.dart';
import '../utils/working_directory_utils.dart';
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
    
    // Linux 特定的权限检查
    await _checkLinuxPermissions();
    
    // Linux 特定的资源文件验证
    await _validateLinuxResources();
    
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

    // 检查工作目录
    await WorkingDirectoryUtils.logWorkingDirectoryInfo();
  }

  /// Linux 特定的权限检查
  static Future<void> _checkLinuxPermissions() async {
    try {
      final hasPermissions = await PermissionUtils.ensureRequiredPermissions();
      if (!hasPermissions) {
        await Logger.logError('权限检查失败，退出应用');
        exit(1);
      }
    } catch (e) {
      await Logger.logError('Linux权限检查异常', e);
    }
  }

  /// Linux 特定的资源文件验证
  static Future<void> _validateLinuxResources() async {
    try {
      final isValid = await PlatformUtils.validateExecutableFile();
      await Logger.logInfo('资源文件验证结果: $isValid');
    } catch (e) {
      await Logger.logError('资源文件验证异常', e);
    }
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

/// Linux 平台入口函数
Future<void> initializePlatform() async {
  await LinuxPlatform.initializePlatform();
}
