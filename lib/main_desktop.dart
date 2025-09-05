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
  // 根据平台调用相应的初始化函数
  if (Platform.isMacOS) {
    await initializeMacOS();
  } else if (Platform.isWindows) {
    await initializeWindows();
  } else if (Platform.isLinux) {
    await initializeLinux();
  } else {
    // 默认初始化（兼容其他平台）
    await _defaultInitialize();
  }
}

// macOS 初始化函数
Future<void> initializeMacOS() async {
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

// Windows 初始化函数
Future<void> initializeWindows() async {
  // 初始化日志系统
  await Logger.initialize();

  // 初始化VPN服务
  VPNService.initialize();

  await Logger.logInfo('=== Windows 应用启动 ===');
  
  // 检查工作目录
  await WorkingDirectoryUtils.logWorkingDirectoryInfo();
  
  // 输出系统信息
  await DebugUtils.debugSystemInfo();
  
  // Windows 特定的权限检查
  try {
    final hasPermissions = await PermissionUtils.ensureRequiredPermissions();
    if (!hasPermissions) {
      await Logger.logError('权限检查失败，退出应用');
      exit(1);
    }
  } catch (e) {
    await Logger.logError('Windows权限检查异常', e);
  }
  
  // 验证资源文件
  try {
    final isValid = await PlatformUtils.validateExecutableFile();
    await Logger.logInfo('资源文件验证结果: $isValid');
    
    // 详细调试资源文件
    await DebugUtils.debugResourceFiles();
  } catch (e) {
    await Logger.logError('资源文件验证异常', e);
  }

  // 设置窗口属性
  await windowManager.ensureInitialized();

  // Windows 特定的窗口设置
  await windowManager.setSize(const Size(400, 630));
  await windowManager.setResizable(false);
  await windowManager.setMinimumSize(const Size(400, 630));
  await windowManager.setMaximumSize(const Size(400, 630));
  await windowManager.setTitle('');
  await windowManager.setClosable(true);
  
  // Windows平台添加窗口关闭事件监听
  windowManager.addListener(_WindowCloseListener());
  
  await windowManager.show();

  // 初始化托盘服务
  try {
    await TrayService.initialize();
    await Logger.logInfo('托盘服务初始化完成');
  } catch (e) {
    await Logger.logError('托盘服务初始化失败，但应用将继续运行', e);
  }

  await Logger.logInfo('Windows 应用启动完成');
}

// Linux 初始化函数
Future<void> initializeLinux() async {
  // 初始化日志系统
  await Logger.initialize();

  // 初始化VPN服务
  VPNService.initialize();

  await Logger.logInfo('=== Linux 应用启动 ===');
  
  // 检查工作目录
  await WorkingDirectoryUtils.logWorkingDirectoryInfo();
  
  // 输出系统信息
  await DebugUtils.debugSystemInfo();
  
  // Linux 特定的权限检查
  try {
    final hasPermissions = await PermissionUtils.ensureRequiredPermissions();
    if (!hasPermissions) {
      await Logger.logError('权限检查失败，退出应用');
      exit(1);
    }
  } catch (e) {
    await Logger.logError('Linux权限检查异常', e);
  }
  
  // 验证资源文件
  try {
    final isValid = await PlatformUtils.validateExecutableFile();
    await Logger.logInfo('资源文件验证结果: $isValid');
    
    // 详细调试资源文件
    await DebugUtils.debugResourceFiles();
  } catch (e) {
    await Logger.logError('资源文件验证异常', e);
  }

  // 设置窗口属性
  await windowManager.ensureInitialized();

  // Linux 特定的窗口设置
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

  await Logger.logInfo('Linux 应用启动完成');
}

// 默认初始化函数（兼容其他平台）
Future<void> _defaultInitialize() async {
  // 初始化日志系统
  await Logger.initialize();

  // 初始化VPN服务
  VPNService.initialize();

  await Logger.logInfo('=== 默认平台应用启动 ===');
  
  // 检查工作目录
  await WorkingDirectoryUtils.logWorkingDirectoryInfo();
  
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

  // 设置窗口属性
  await windowManager.ensureInitialized();

  // 默认窗口设置
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

  await Logger.logInfo('默认平台应用启动完成');
}

/// 清理并退出应用
Future<void> _cleanupAndExit() async {
  try {
    await Logger.logInfo('开始清理应用资源...');
    
    // 检查是否处于连接状态
    if (VPNService.isConnected) {
      await Logger.logInfo('检测到VPN连接状态，正在断开连接...');
      try {
        final success = await VPNService.disconnect();
        if (success) {
          await Logger.logInfo('VPN连接已断开，core进程已清理');
        } else {
          await Logger.logWarning('VPN断开连接失败，但继续退出应用');
        }
      } catch (e) {
        await Logger.logError('VPN断开连接时发生错误', e);
      }
    } else {
      await Logger.logInfo('未检测到VPN连接状态');
    }
    
    // 销毁托盘图标
    try {
      await TrayService.hide();
      await Logger.logInfo('托盘图标已销毁');
    } catch (e) {
      await Logger.logError('销毁托盘图标失败', e);
    }
    
    // Windows平台强制清理core进程
    if (Platform.isWindows) {
      await _forceCleanupWindowsProcesses();
    }
    
    await Logger.logInfo('应用清理完成，准备退出');
    
    // 退出应用
    exit(0);
  } catch (e) {
    await Logger.logError('清理应用时发生错误', e);
    // 即使清理失败也要退出
    exit(1);
  }
}

/// Windows平台强制清理进程
Future<void> _forceCleanupWindowsProcesses() async {
  try {
    await Logger.logInfo('开始强制清理Windows进程...');
    
    // 使用Process.run执行taskkill命令
    final result = await Process.run(
      'taskkill',
      ['/F', '/IM', 'appfast-core_windows_amd64.exe'],
      runInShell: true,
    );
    
    if (result.exitCode == 0) {
      await Logger.logInfo('成功清理core进程');
    } else {
      await Logger.logInfo('没有找到需要清理的core进程或清理失败: ${result.stderr}');
    }
    
    // 也尝试清理arm64版本
    final result2 = await Process.run(
      'taskkill',
      ['/F', '/IM', 'appfast-core_windows_arm64.exe'],
      runInShell: true,
    );
    
    if (result2.exitCode == 0) {
      await Logger.logInfo('成功清理core进程(arm64)');
    }
    
  } catch (e) {
    await Logger.logError('强制清理Windows进程失败', e);
  }
}

/// Windows窗口关闭监听器
class _WindowCloseListener with WindowListener {
  @override
  void onWindowClose() async {
    await Logger.logInfo('检测到窗口关闭事件，开始清理进程...');
    await _cleanupAndExit();
  }
}