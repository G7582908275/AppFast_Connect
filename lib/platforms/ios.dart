import '../utils/logger.dart';
import '../services/vpn_service.dart';

/// iOS 平台初始化器
class IOSPlatform {
  /// iOS 特定的初始化流程
  static Future<void> initializePlatform() async {
    await Logger.logInfo('=== iOS 应用启动 ===');
    
    // 执行通用初始化
    await _initializeCommon();
        
    // 记录启动完成
    await Logger.logInfo('iOS 应用启动完成');
  }

  /// 通用初始化步骤
  static Future<void> _initializeCommon() async {
    // 初始化日志系统
    await Logger.initialize();

    // 初始化VPN服务
    VPNService.initialize();

  }
}

/// iOS 平台入口函数
Future<void> initializePlatform() async {
  await IOSPlatform.initializePlatform();
}
