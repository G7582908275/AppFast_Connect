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
import 'services/windows_firewall_service.dart';
import 'services/process_cleanup_service.dart';
import 'services/vpn_service.dart';

Future<void> initializePlatform() async {
  // 初始化日志系统
  await Logger.initialize();

  // 初始化VPN服务
  VPNService.initialize();

  // 在 macOS 上，首先检查并请求管理员权限
  if (Platform.isMacOS) {
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
  }

  // Windows平台防火墙规则设置
  if (Platform.isWindows) {
    await Logger.logInfo('=== Windows 应用启动 ===');
    
    try {
      // 添加Windows防火墙规则
      final firewallResult = await WindowsFirewallService.addFirewallRules();
      if (firewallResult) {
        await Logger.logInfo('Windows防火墙规则设置成功');
      } else {
        await Logger.logWarning('Windows防火墙规则设置失败，但应用将继续运行');
      }
    } catch (e) {
      await Logger.logError('Windows防火墙规则设置时发生错误', e);
    }
  }

  // 设置窗口属性
  await windowManager.ensureInitialized();

  // 设置窗口尺寸为400x630，并禁用调整大小
  await windowManager.setSize(const Size(400, 630));
  await windowManager.setResizable(false);
  await windowManager.setMinimumSize(const Size(400, 630));
  await windowManager.setMaximumSize(const Size(400, 630));

  // 设置窗口标题
  await windowManager.setTitle('');
  await windowManager.show();

  // 注册应用退出时的清理处理
  _registerExitHandlers();

  await Logger.logInfo('应用启动完成');
}

/// 注册应用退出时的清理处理
void _registerExitHandlers() {
  // 注册进程退出信号处理
  ProcessSignal.sigterm.watch().listen((_) async {
    await Logger.logInfo('收到SIGTERM信号，开始清理...');
    await ProcessCleanupService.thoroughCleanup();
  });
  
  ProcessSignal.sigint.watch().listen((_) async {
    await Logger.logInfo('收到SIGINT信号，开始清理...');
    await ProcessCleanupService.thoroughCleanup();
  });
  
  // 注册应用退出时的清理
  _registerAppExitHandler();
}

/// 注册应用退出时的清理处理
void _registerAppExitHandler() {
  // 使用Timer定期检查应用是否还在运行
  Timer.periodic(Duration(seconds: 30), (timer) async {
    try {
      // 检查是否有AppFast Connect相关进程在运行
      final hasProcesses = await ProcessCleanupService.hasAppFastConnectProcessesRunning();
      if (hasProcesses) {
        await Logger.logInfo('检测到AppFast Connect相关进程在运行，执行清理...');
        await ProcessCleanupService.thoroughCleanup();
      }
    } catch (e) {
      await Logger.logError('定期检查进程时发生错误: $e');
    }
  });
}
