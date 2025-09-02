import 'dart:io';
import 'logger.dart';
import 'platform_utils.dart';

class DebugUtils {
  /// 输出系统信息
  static Future<void> debugSystemInfo() async {
    await Logger.logInfo('=== 系统信息调试 ===');
    
    try {
      // 操作系统信息
      await Logger.logInfo('操作系统: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      await Logger.logInfo('本地化: ${Platform.localeName}');
      await Logger.logInfo('路径分隔符: ${Platform.pathSeparator}');
      
      // 环境变量
      final envVars = Platform.environment;
      await Logger.logInfo('环境变量数量: ${envVars.length}');
      
      // 当前工作目录
      final currentDir = Directory.current;
      await Logger.logInfo('当前工作目录: ${currentDir.path}');
      
      // 用户目录
      final userDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      await Logger.logInfo('用户目录: $userDir');
      
      // 应用数据目录
      final appDataDir = Platform.environment['APPDATA'] ?? 
                        Platform.environment['XDG_DATA_HOME'] ?? 
                        '$userDir/Library/Application Support';
      await Logger.logInfo('应用数据目录: $appDataDir');
      
    } catch (e) {
      await Logger.logError('获取系统信息时出错', e);
    }
  }

  /// 调试资源文件
  static Future<void> debugResourceFiles() async {
    await Logger.logInfo('=== 资源文件调试 ===');
    
    try {
      // 检查可执行文件
      try {
        final executablePath = await PlatformUtils.getExecutablePath();
        await Logger.logInfo('可执行文件路径: $executablePath');
        
        if (executablePath.isNotEmpty) {
          final executableFile = File(executablePath);
          if (await executableFile.exists()) {
            final stat = await executableFile.stat();
            await Logger.logInfo('可执行文件存在，大小: ${stat.size} 字节');
            await Logger.logInfo('可执行文件权限: ${stat.mode}');
            await Logger.logInfo('最后修改时间: ${stat.modified}');
          } else {
            await Logger.logWarning('可执行文件不存在: $executablePath');
          }
        } else {
          await Logger.logWarning('无法获取可执行文件路径');
        }
      } catch (e) {
        await Logger.logError('获取可执行文件路径失败', e);
      }
      
      // 检查assets目录
      final assetsDir = Directory('assets');
      if (await assetsDir.exists()) {
        await Logger.logInfo('assets目录存在');
        await _listDirectoryContents(assetsDir, 'assets');
      } else {
        await Logger.logWarning('assets目录不存在');
      }
      
      // 检查libs目录
      final libsDir = Directory('assets/libs');
      if (await libsDir.exists()) {
        await Logger.logInfo('libs目录存在');
        await _listDirectoryContents(libsDir, 'assets/libs');
      } else {
        await Logger.logWarning('libs目录不存在');
      }
      
    } catch (e) {
      await Logger.logError('调试资源文件时出错', e);
    }
  }

  /// 列出目录内容
  static Future<void> _listDirectoryContents(Directory dir, String path) async {
    try {
      final entities = await dir.list().toList();
      await Logger.logInfo('$path 目录包含 ${entities.length} 个项目');
      
      for (final entity in entities) {
        if (entity is File) {
          final stat = await entity.stat();
          await Logger.logInfo('  文件: ${entity.path.split('/').last} (${stat.size} 字节)');
        } else if (entity is Directory) {
          await Logger.logInfo('  目录: ${entity.path.split('/').last}');
        }
      }
    } catch (e) {
      await Logger.logError('列出目录内容时出错: $path', e);
    }
  }
} 
