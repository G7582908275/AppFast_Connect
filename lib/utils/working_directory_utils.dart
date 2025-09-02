import 'dart:io';
import 'logger.dart';

class WorkingDirectoryUtils {
  /// 检查并记录工作目录信息
  static Future<void> logWorkingDirectoryInfo() async {
    try {
      await Logger.logInfo('=== 工作目录信息 ===');
      
      // 当前工作目录
      final currentDir = Directory.current;
      await Logger.logInfo('当前工作目录: ${currentDir.path}');
      
      // 应用可执行路径
      await Logger.logInfo('应用可执行路径: ${Platform.resolvedExecutable}');
      
      // 检查工作目录权限
      try {
        final testFile = File('${currentDir.path}/test_workdir.txt');
        await testFile.writeAsString('test');
        await testFile.delete();
        await Logger.logInfo('当前工作目录可写');
      } catch (e) {
        await Logger.logWarning('当前工作目录只读: $e');
      }
      
      // 检查/tmp目录
      final tmpDir = Directory('/tmp/appfast_connect');
      try {
        if (!await tmpDir.exists()) {
          await tmpDir.create(recursive: true);
        }
        final testFile = File('${tmpDir.path}/test_tmp.txt');
        await testFile.writeAsString('test');
        await testFile.delete();
        await Logger.logInfo('/tmp/appfast_connect目录可写');
      } catch (e) {
        await Logger.logError('/tmp/appfast_connect目录不可写: $e');
      }
      
      await Logger.logInfo('=== 工作目录信息结束 ===');
    } catch (e) {
      await Logger.logError('检查工作目录时发生错误', e);
    }
  }
  
  /// 获取推荐的工作目录
  static String getRecommendedWorkingDirectory() {
    final currentDir = Directory.current.path;
    
    // 如果当前在Applications目录中，使用/tmp
    if (currentDir.contains('/Applications/') || currentDir.contains('/Applications (Parallels)/')) {
      return '/tmp/appfast_connect/vpn_work';
    }
    
    // 否则使用当前目录下的临时目录
    return '$currentDir/tmp/vpn_work';
  }
}
