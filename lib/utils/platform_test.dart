import 'dart:io';
import 'platform_utils.dart';
import 'permission_utils.dart';
import 'logger.dart';

/// 平台功能测试类
class PlatformTest {
  /// 运行所有平台测试
  static Future<void> runAllTests() async {
    await Logger.logInfo('=== 开始平台功能测试 ===');
    
    // 测试平台检测
    await _testPlatformDetection();
    
    // 测试架构检测
    await _testArchitectureDetection();
    
    // 测试文件路径处理
    await _testFilePathHandling();
    
    // 测试权限检查
    await _testPermissionChecking();
    
    // 测试工作目录和环境变量
    await _testWorkingDirectoryAndEnv();
    
    await Logger.logInfo('=== 平台功能测试完成 ===');
  }
  
  /// 测试平台检测
  static Future<void> _testPlatformDetection() async {
    await Logger.logInfo('--- 测试平台检测 ---');
    await Logger.logInfo('isMacOS: ${PlatformUtils.isMacOS}');
    await Logger.logInfo('isWindows: ${PlatformUtils.isWindows}');
    await Logger.logInfo('isLinux: ${PlatformUtils.isLinux}');
    await Logger.logInfo('当前平台: ${Platform.operatingSystem}');
  }
  
  /// 测试架构检测
  static Future<void> _testArchitectureDetection() async {
    await Logger.logInfo('--- 测试架构检测 ---');
    final arch = PlatformUtils.architecture;
    await Logger.logInfo('检测到的架构: $arch');
    await Logger.logInfo('库文件名: ${PlatformUtils.libraryFileName}');
    await Logger.logInfo('库路径: ${PlatformUtils.libraryPath}');
  }
  
  /// 测试文件路径处理
  static Future<void> _testFilePathHandling() async {
    await Logger.logInfo('--- 测试文件路径处理 ---');
    try {
      final executablePath = await PlatformUtils.getExecutablePath();
      await Logger.logInfo('可执行文件路径: $executablePath');
      
      final isValid = await PlatformUtils.validateExecutableFile();
      await Logger.logInfo('可执行文件验证: $isValid');
    } catch (e) {
      await Logger.logError('文件路径处理测试失败', e);
    }
  }
  
  /// 测试权限检查
  static Future<void> _testPermissionChecking() async {
    await Logger.logInfo('--- 测试权限检查 ---');
    try {
      final isAdmin = await PermissionUtils.isRunningAsAdmin();
      await Logger.logInfo('是否以管理员身份运行: $isAdmin');
      
      final hasNetworkPermission = await PermissionUtils.hasNetworkExtensionPermission();
      await Logger.logInfo('是否有网络扩展权限: $hasNetworkPermission');
      
      final hasSudo = await PermissionUtils.hasSudoPrivileges();
      await Logger.logInfo('是否有sudo权限: $hasSudo');
    } catch (e) {
      await Logger.logError('权限检查测试失败', e);
    }
  }
  
  /// 测试工作目录和环境变量
  static Future<void> _testWorkingDirectoryAndEnv() async {
    await Logger.logInfo('--- 测试工作目录和环境变量 ---');
    try {
      final workingDir = await PlatformUtils.getWorkingDirectory();
      await Logger.logInfo('工作目录: $workingDir');
      
      final envVars = PlatformUtils.getEnvironmentVariables();
      await Logger.logInfo('环境变量: $envVars');
    } catch (e) {
      await Logger.logError('工作目录和环境变量测试失败', e);
    }
  }
  
  /// 测试资源文件加载
  static Future<void> testAssetLoading() async {
    await Logger.logInfo('--- 测试资源文件加载 ---');
    try {
      final assetPath = PlatformUtils.libraryPath;
      await Logger.logInfo('尝试加载资源文件: $assetPath');
      
      final bytes = await PlatformUtils.loadAssetBytes(assetPath);
      await Logger.logInfo('资源文件加载成功: ${bytes.length} bytes');
    } catch (e) {
      await Logger.logError('资源文件加载测试失败', e);
    }
  }
}
