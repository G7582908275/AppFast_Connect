
import 'dart:io';
import 'package:flutter/services.dart';
import 'logger.dart';

class PlatformUtils {
  static bool get isMacOS => Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  
  static String get architecture {
    if (Platform.isMacOS) {
      // 检测 macOS 的芯片架构
      try {
        final result = Process.runSync('uname', ['-m']);
        final arch = result.stdout.toString().trim();
        return arch == 'arm64' ? 'arm64' : 'x64';
      } catch (e) {
        // 如果检测失败，默认返回 arm64（M1/M2 芯片）
        return 'arm64';
      }
    } else if (Platform.isWindows) {
      return 'x64';
    } else if (Platform.isLinux) {
      return 'x64';
    }
    return 'unknown';
  }
  
  static String get libraryFileName {
    if (Platform.isMacOS) {
      final arch = architecture;
      return 'IpamSdnSingClientCore_darwin_$arch';
    } else if (Platform.isWindows) {
      return 'IpamSdnSingClientCore_windows_x64.exe';
    } else if (Platform.isLinux) {
      return 'IpamSdnSingClientCore_linux_x64';
    }
    throw UnsupportedError('Unsupported platform');
  }
  
  static String get libraryPath {
    // 新的assets结构：只有一个core文件
    return 'assets/libs/core';
  }
  


  // 专门处理macOS打包后assets访问的方法
  static Future<Uint8List> loadAssetBytes(String assetPath) async {
    try {
      // 方法1: 使用rootBundle.load
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      await Logger.logInfo('成功通过rootBundle加载资源文件: $assetPath (${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      await Logger.logWarning('rootBundle加载失败，尝试其他方法: $e');
      
      if (Platform.isMacOS) {
        try {
          // 方法2: 尝试从应用包内直接读取
          final appBundlePath = await _getAppBundlePath();
          final directPath = '$appBundlePath/Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/$assetPath';
          await Logger.logInfo('尝试直接读取: $directPath');
          
          final directFile = File(directPath);
          if (await directFile.exists()) {
            final bytes = await directFile.readAsBytes();
            await Logger.logInfo('成功通过直接路径加载资源文件: $assetPath (${bytes.length} bytes)');
            return bytes;
          } else {
            await Logger.logError('直接路径文件不存在: $directPath');
          }
        } catch (e2) {
          await Logger.logError('直接路径读取失败', e2);
        }
        
        try {
          // 方法3: 尝试从当前工作目录查找
          final currentDir = Directory.current.path;
          final relativePath = '$currentDir/flutter_assets/$assetPath';
          await Logger.logInfo('尝试从当前目录读取: $relativePath');
          
          final relativeFile = File(relativePath);
          if (await relativeFile.exists()) {
            final bytes = await relativeFile.readAsBytes();
            await Logger.logInfo('成功通过相对路径加载资源文件: $assetPath (${bytes.length} bytes)');
            return bytes;
          } else {
            await Logger.logError('相对路径文件不存在: $relativePath');
          }
        } catch (e3) {
          await Logger.logError('相对路径读取失败', e3);
        }
      }
      
      throw Exception('所有加载方法都失败，无法访问assets文件: $assetPath');
    }
  }

  static Future<String> getExecutablePath() async {
    try {
      final fileName = libraryFileName;
      final assetPath = libraryPath;
      
      // 使用 /tmp 目录（在Applications文件夹中运行时更可靠）
      final tempDir = Directory('/tmp');
      final executableDir = Directory('${tempDir.path}/appfast_connect');
      
      // 确保目录存在
      if (!await executableDir.exists()) {
        await executableDir.create(recursive: true);
      }
      
      final executablePath = '${executableDir.path}/$fileName';
      
      // 检查文件是否已经存在且有效
      final file = File(executablePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          // 确保文件有执行权限
          await _ensureExecutablePermission(executablePath);
          await Logger.logInfo('使用现有可执行文件: $executablePath ($fileSize bytes)');
          return executablePath;
        } else {
          await Logger.logWarning('现有文件大小为0，重新释放: $executablePath');
          await file.delete();
        }
      }
      
      // 从assets复制文件并重命名
      await Logger.logInfo('正在释放资源文件: $assetPath -> $executablePath');
      
      // 使用新的加载方法
      final bytes = await loadAssetBytes(assetPath);
      
      // 写入文件
      await file.writeAsBytes(bytes);
      
      // 设置执行权限
      await _ensureExecutablePermission(executablePath);
      
      final finalSize = await file.length();
      await Logger.logInfo('资源文件释放完成: $executablePath ($finalSize bytes)');
      return executablePath;
    } catch (e) {
      await Logger.logError('资源文件释放失败', e);
      rethrow;
    }
  }
  
  static Future<void> _ensureExecutablePermission(String filePath) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        // 在 Unix 系统上设置执行权限
        final result = await Process.run('chmod', ['+x', filePath]);
        if (result.exitCode != 0) {
          await Logger.logError('设置执行权限失败: ${result.stderr}');
        } else {
          await Logger.logInfo('执行权限设置成功: $filePath');
        }
      }
    } catch (e) {
      await Logger.logError('设置执行权限时发生错误', e);
    }
  }
  
  // 添加资源文件验证方法
  static Future<bool> validateExecutableFile() async {
    try {
      final executablePath = await getExecutablePath();
      final file = File(executablePath);
      
      if (!await file.exists()) {
        await Logger.logError('可执行文件不存在: $executablePath');
        return false;
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        await Logger.logError('可执行文件大小为0: $executablePath');
        return false;
      }
      
      // 检查文件权限
      final stat = await file.stat();
      final isExecutable = stat.mode & 0x1 != 0;
      
      if (!isExecutable) {
        await Logger.logWarning('文件没有执行权限，尝试设置: $executablePath');
        await _ensureExecutablePermission(executablePath);
      }
      
      await Logger.logInfo('可执行文件验证成功: $executablePath ($fileSize bytes)');
      return true;
    } catch (e) {
      await Logger.logError('可执行文件验证失败', e);
      return false;
    }
  }
  
  // 获取应用包路径的辅助方法
  static Future<String> _getAppBundlePath() async {
    try {
      // 在macOS上，应用通常位于.app包内
      final process = await Process.run('ps', ['-o', 'comm=']);
      final executablePath = process.stdout.toString().trim();
      
      // 查找.app包路径
      if (executablePath.contains('.app')) {
        final appMatch = RegExp(r'(.+\.app)').firstMatch(executablePath);
        if (appMatch != null) {
          return appMatch.group(1)!;
        }
      }
      
      // 如果无法从进程获取，尝试从当前可执行文件路径推断
      final currentDir = Directory.current.path;
      if (currentDir.contains('.app')) {
        final appMatch = RegExp(r'(.+\.app)').firstMatch(currentDir);
        if (appMatch != null) {
          return appMatch.group(1)!;
        }
      }
      
      throw Exception('无法确定应用包路径');
    } catch (e) {
      await Logger.logError('获取应用包路径失败', e);
      rethrow;
    }
  }
}
