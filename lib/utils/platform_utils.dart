
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
      // Windows 架构检测
      try {
        final result = Process.runSync('wmic', ['os', 'get', 'osarchitecture']);
        final output = result.stdout.toString().toLowerCase();
        if (output.contains('arm64')) {
          return 'arm64';
        } else {
          return 'x64';
        }
      } catch (e) {
        // 如果检测失败，默认返回 x64
        return 'x64';
      }
    } else if (Platform.isLinux) {
      // Linux 架构检测
      try {
        final result = Process.runSync('uname', ['-m']);
        final arch = result.stdout.toString().trim();
        if (arch == 'aarch64' || arch == 'arm64') {
          return 'arm64';
        } else if (arch == 'x86_64' || arch == 'amd64') {
          return 'x64';
        } else {
          return 'x64'; // 默认返回 x64
        }
      } catch (e) {
        // 如果检测失败，默认返回 x64
        return 'x64';
      }
    }
    return 'unknown';
  }
  
  static String get libraryFileName {
    if (Platform.isMacOS) {
      final arch = architecture;
      return 'core';
    } else if (Platform.isWindows) {
      return 'core.exe';
    } else if (Platform.isLinux) {
      return 'core';
    }
    throw UnsupportedError('Unsupported platform');
  }
  
  static String get libraryPath {
    // 所有平台都使用相同的assets路径
    return 'assets/libs/core';
  }

  // 专门处理不同平台assets访问的方法
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
      } else if (Platform.isWindows) {
        try {
          // Windows: 尝试从应用目录读取
          final currentDir = Directory.current.path;
          final relativePath = '$currentDir/data/flutter_assets/$assetPath';
          await Logger.logInfo('尝试从Windows应用目录读取: $relativePath');
          
          final relativeFile = File(relativePath);
          if (await relativeFile.exists()) {
            final bytes = await relativeFile.readAsBytes();
            await Logger.logInfo('成功通过Windows路径加载资源文件: $assetPath (${bytes.length} bytes)');
            return bytes;
          } else {
            await Logger.logError('Windows路径文件不存在: $relativePath');
          }
        } catch (e2) {
          await Logger.logError('Windows路径读取失败', e2);
        }
      } else if (Platform.isLinux) {
        try {
          // Linux: 尝试从应用目录读取
          final currentDir = Directory.current.path;
          final relativePath = '$currentDir/data/flutter_assets/$assetPath';
          await Logger.logInfo('尝试从Linux应用目录读取: $relativePath');
          
          final relativeFile = File(relativePath);
          if (await relativeFile.exists()) {
            final bytes = await relativeFile.readAsBytes();
            await Logger.logInfo('成功通过Linux路径加载资源文件: $assetPath (${bytes.length} bytes)');
            return bytes;
          } else {
            await Logger.logError('Linux路径文件不存在: $relativePath');
          }
        } catch (e2) {
          await Logger.logError('Linux路径读取失败', e2);
        }
      }
      
      throw Exception('所有加载方法都失败，无法访问assets文件: $assetPath');
    }
  }

  static Future<String> getExecutablePath() async {
    try {
      final fileName = libraryFileName;
      final assetPath = libraryPath;
      
      // 根据平台选择临时目录
      String tempDirPath;
      if (Platform.isMacOS) {
        tempDirPath = '/tmp';
      } else if (Platform.isWindows) {
        tempDirPath = Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
      } else if (Platform.isLinux) {
        tempDirPath = '/tmp';
      } else {
        throw UnsupportedError('Unsupported platform');
      }
      
      final tempDir = Directory(tempDirPath);
      final executableDir = Directory('${tempDir.path}/appfast_connect');
      
      // 确保目录存在
      if (!await executableDir.exists()) {
        await executableDir.create(recursive: true);
      }
      
      final executablePath = '${executableDir.path}/$fileName';
      
      // 每次启动都删除现有文件并重新复制
      final file = File(executablePath);
      if (await file.exists()) {
        await Logger.logInfo('删除现有可执行文件: $executablePath');
        await file.delete();
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
      } else if (Platform.isWindows) {
        // Windows 不需要设置执行权限，但可以验证文件完整性
        final file = File(filePath);
        if (await file.exists()) {
          final fileSize = await file.length();
          await Logger.logInfo('Windows可执行文件验证成功: $filePath ($fileSize bytes)');
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
      
      // 检查文件权限（仅在Unix系统上）
      if (Platform.isMacOS || Platform.isLinux) {
        final stat = await file.stat();
        final isExecutable = stat.mode & 0x1 != 0;
        
        if (!isExecutable) {
          await Logger.logWarning('文件没有执行权限，尝试设置: $executablePath');
          await _ensureExecutablePermission(executablePath);
        }
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
  
  // 获取平台特定的工作目录
  static Future<String> getWorkingDirectory() async {
    if (Platform.isMacOS) {
      return '/tmp/appfast_connect';
    } else if (Platform.isWindows) {
      final tempDir = Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
      return '$tempDir\\appfast_connect';
    } else if (Platform.isLinux) {
      return '/tmp/appfast_connect';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  // 获取平台特定的环境变量
  static Map<String, String> getEnvironmentVariables() {
    if (Platform.isMacOS) {
      return {
        'HOME': '/tmp/appfast_connect',
        'TMPDIR': '/tmp/appfast_connect',
      };
    } else if (Platform.isWindows) {
      final tempDir = Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
      return {
        'TEMP': tempDir,
        'TMP': tempDir,
      };
    } else if (Platform.isLinux) {
      return {
        'HOME': '/tmp/appfast_connect',
        'TMPDIR': '/tmp/appfast_connect',
      };
    } else {
      return {};
    }
  }
  
  /// 清理临时目录中的可执行文件
  static Future<void> cleanupExecutableFiles() async {
    try {
      final fileName = libraryFileName;
      
      // 根据平台选择临时目录
      String tempDirPath;
      if (Platform.isMacOS) {
        tempDirPath = '/tmp';
      } else if (Platform.isWindows) {
        tempDirPath = Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
      } else if (Platform.isLinux) {
        tempDirPath = '/tmp';
      } else {
        return; // 不支持的平台直接返回
      }
      
      final tempDir = Directory(tempDirPath);
      final executableDir = Directory('${tempDir.path}/appfast_connect');
      
      if (await executableDir.exists()) {
        final executablePath = '${executableDir.path}/$fileName';
        final file = File(executablePath);
        
        if (await file.exists()) {
          await Logger.logInfo('清理临时可执行文件: $executablePath');
          await file.delete();
        }
        
        // 尝试删除整个目录（如果为空）
        try {
          final contents = await executableDir.list().toList();
          if (contents.isEmpty) {
            await executableDir.delete();
            await Logger.logInfo('删除空的临时目录: ${executableDir.path}');
          }
        } catch (e) {
          // 目录不为空或删除失败，忽略错误
          await Logger.logInfo('临时目录不为空，保留目录: ${executableDir.path}');
        }
      }
    } catch (e) {
      await Logger.logError('清理临时文件时发生错误', e);
    }
  }
}
