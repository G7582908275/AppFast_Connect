import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'utils/permission_utils.dart';
import 'utils/platform_utils.dart';
import 'utils/debug_utils.dart';
import 'utils/logger.dart';
import 'utils/applications_folder_utils.dart';
import 'utils/working_directory_utils.dart';
import 'services/vpn_service.dart';
import 'services/tray_service.dart';

Future<void> initializePlatform() async {
  // 初始化日志系统
  await Logger.initialize();

  // 初始化VPN服务
  VPNService.initialize();

  await Logger.logInfo('=== macOS 应用启动 ===');
  
  // 检查工作目录
  await WorkingDirectoryUtils.logWorkingDirectoryInfo();
  
  // 检查Applications文件夹权限
  await ApplicationsFolderUtils.logDetailedPermissions();
  final hasAppPermissions = await ApplicationsFolderUtils.checkApplicationsPermissions();
  
  if (!hasAppPermissions) {
    await Logger.logWarning('Applications文件夹权限不足，尝试修复...');
    final fixed = await ApplicationsFolderUtils.fixApplicationsPermissions();
    if (!fixed) {
      await Logger.logError('无法修复Applications文件夹权限，应用可能无法正常工作');
    }
  }
  
  // 输出系统信息
  await DebugUtils.debugSystemInfo();
  
  // 验证资源文件
  try {
    final isValid = await PlatformUtils.validateExecutableFile();
    await Logger.logInfo('资源文件验证结果: $isValid');
    
    // 详细调试资源文件
    await DebugUtils.debugResourceFiles();
  } catch (e) {
    await Logger.logError('资源文件验证异常', e);
  }
  
  final hasPermissions = await PermissionUtils.ensureRequiredPermissions();
  if (!hasPermissions) {
    await Logger.logError('权限检查失败，退出应用');
    exit(1);
  }

  // 设置窗口属性
  await windowManager.ensureInitialized();

  // macOS 特定的窗口设置
  await windowManager.setSize(const Size(400, 630));
  await windowManager.setResizable(false);
  await windowManager.setMinimumSize(const Size(400, 630));
  await windowManager.setMaximumSize(const Size(400, 630));
  await windowManager.setTitle('');
  await windowManager.setClosable(true);
  await windowManager.show();

  // 初始化托盘服务
  try {
    await TrayService.initialize();
    await Logger.logInfo('托盘服务初始化完成');
  } catch (e) {
    await Logger.logError('托盘服务初始化失败，但应用将继续运行', e);
  }

  await Logger.logInfo('macOS 应用启动完成');
}
