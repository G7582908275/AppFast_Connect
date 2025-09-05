import '../utils/permission_utils.dart';
import '../utils/logger.dart';
import '../utils/working_directory_utils.dart';
import '../services/vpn_service.dart';

/// iOS 平台初始化器
class IOSPlatform {
  /// iOS 特定的初始化流程
  static Future<void> initializePlatform() async {
    await Logger.logInfo('=== iOS 应用启动 ===');
    
    // 执行通用初始化
    await _initializeCommon();
    
    // iOS 特定的权限检查
    await _checkIOSPermissions();
    
    // 记录启动完成
    await Logger.logInfo('iOS 应用启动完成');
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

  /// iOS 特定的权限检查
  static Future<void> _checkIOSPermissions() async {
    try {
      final hasPermissions = await PermissionUtils.ensureRequiredPermissions();
      if (!hasPermissions) {
        await Logger.logError('权限检查失败，应用可能无法正常工作');
      }
    } catch (e) {
      await Logger.logError('iOS权限检查异常', e);
    }
  }
}

/// iOS 平台入口函数
Future<void> initializePlatform() async {
  await IOSPlatform.initializePlatform();
}
