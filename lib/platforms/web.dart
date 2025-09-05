import '../utils/platform_utils.dart';
import '../utils/logger.dart';
import '../services/vpn_service.dart';

/// Web 平台初始化器
class WebPlatform {
  /// Web 特定的初始化流程
  static Future<void> initializePlatform() async {
    await Logger.logInfo('=== Web 应用启动 ===');
    
    // 执行通用初始化
    await _initializeCommon();
    
    // Web 特定的资源文件验证
    await _validateWebResources();
    
    // 记录启动完成
    await Logger.logInfo('Web 应用启动完成');
  }

  /// 通用初始化步骤
  static Future<void> _initializeCommon() async {
    // 初始化日志系统
    await Logger.initialize();

    // 初始化VPN服务
    VPNService.initialize();

  }

  /// Web 特定的资源文件验证
  static Future<void> _validateWebResources() async {
    try {
      final isValid = await PlatformUtils.validateExecutableFile();
      await Logger.logInfo('资源文件验证结果: $isValid');
    } catch (e) {
      await Logger.logError('资源文件验证异常', e);
    }
  }
}

/// Web 平台入口函数
Future<void> initializePlatform() async {
  await WebPlatform.initializePlatform();
}
