import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'logger.dart';

class ApplicationsFolderUtils {
  /// 检查应用是否在Applications文件夹中运行
  static bool get isRunningFromApplications {
    final executablePath = Platform.resolvedExecutable;
    return executablePath.contains('/Applications/') || 
           executablePath.contains('/Applications (Parallels)/');
  }
  
  /// 获取应用在Applications文件夹中的路径
  static String? get applicationsPath {
    final executablePath = Platform.resolvedExecutable;
    if (executablePath.contains('/Applications/')) {
      // 提取应用包路径
      final parts = executablePath.split('/Contents/');
      if (parts.isNotEmpty) {
        return parts[0];
      }
    }
    return null;
  }
  
  /// 检查应用是否有必要的权限
  static Future<bool> checkApplicationsPermissions() async {
    try {
      await Logger.logInfo('检查Applications文件夹权限...');
      
      if (!isRunningFromApplications) {
        await Logger.logInfo('应用不在Applications文件夹中运行');
        return true;
      }
      
      await Logger.logInfo('应用在Applications文件夹中运行: $applicationsPath');
      
      // 检查/tmp目录权限
      final tmpDir = Directory('/tmp/appfast_connect');
      final testFile = File('${tmpDir.path}/test_permission.txt');
      
      try {
        if (!await tmpDir.exists()) {
          await tmpDir.create(recursive: true);
        }
        await testFile.writeAsString('test');
        await testFile.delete();
        await Logger.logInfo('/tmp目录权限正常');
      } catch (e) {
        await Logger.logError('/tmp目录权限不足', e);
        return false;
      }
      
      await Logger.logInfo('Applications文件夹权限检查完成');
      return true;
    } catch (e) {
      await Logger.logError('权限检查过程中发生错误', e);
      return false;
    }
  }
  
  /// 修复Applications文件夹权限问题
  static Future<bool> fixApplicationsPermissions() async {
    try {
      await Logger.logInfo('尝试修复Applications文件夹权限...');
      
      if (!isRunningFromApplications) {
        await Logger.logInfo('应用不在Applications文件夹中，无需修复');
        return true;
      }
      
      final appPath = applicationsPath;
      if (appPath == null) {
        await Logger.logError('无法获取应用路径');
        return false;
      }
      
      // 尝试修复应用包权限
      final result = await Process.run('chmod', ['-R', '755', appPath]);
      if (result.exitCode == 0) {
        await Logger.logInfo('应用包权限修复成功');
      } else {
        await Logger.logWarning('应用包权限修复失败: ${result.stderr}');
      }
      
      // 尝试修复应用文档目录权限
      final appDocDir = await getApplicationDocumentsDirectory();
      final docResult = await Process.run('chmod', ['-R', '755', appDocDir.path]);
      if (docResult.exitCode == 0) {
        await Logger.logInfo('应用文档目录权限修复成功');
      } else {
        await Logger.logWarning('应用文档目录权限修复失败: ${docResult.stderr}');
      }
      
      return true;
    } catch (e) {
      await Logger.logError('修复权限过程中发生错误', e);
      return false;
    }
  }
  
  /// 获取详细的权限信息
  static Future<void> logDetailedPermissions() async {
    try {
      await Logger.logInfo('=== 详细权限信息 ===');
      
      // 应用路径信息
      await Logger.logInfo('应用可执行路径: ${Platform.resolvedExecutable}');
      await Logger.logInfo('是否在Applications文件夹: $isRunningFromApplications');
      await Logger.logInfo('Applications路径: ${applicationsPath ?? "N/A"}');
      
      // 检查/tmp目录权限
      final tmpDir = Directory('/tmp/appfast_connect');
      if (await tmpDir.exists()) {
        final stat = await tmpDir.stat();
        await Logger.logInfo('/tmp/appfast_connect目录权限: ${stat.mode.toRadixString(8)}');
      } else {
        await Logger.logInfo('/tmp/appfast_connect目录不存在');
      }
      
      await Logger.logInfo('=== 权限信息结束 ===');
    } catch (e) {
      await Logger.logError('获取权限信息时发生错误', e);
    }
  }
}
