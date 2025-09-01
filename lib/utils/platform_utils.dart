import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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
    final fileName = libraryFileName;
    final platformFolder = _getPlatformFolder();
    return 'assets/libs/$platformFolder/$fileName';
  }
  
  static Future<String> getExecutablePath() async {
    try {
      final fileName = libraryFileName;
      final assetPath = libraryPath;
      
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final executablePath = '${tempDir.path}/$fileName';
      
      // 检查文件是否已经存在
      final file = File(executablePath);
      if (await file.exists()) {
        // 确保文件有执行权限
        await _ensureExecutablePermission(executablePath);
        return executablePath;
      }
      
      // 从assets复制文件
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      
      // 写入文件
      await file.writeAsBytes(bytes);
      
      // 设置执行权限
      await _ensureExecutablePermission(executablePath);
      
      return executablePath;
    } catch (e) {
      rethrow;
    }
  }
  
  static Future<void> _ensureExecutablePermission(String filePath) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        // 在 Unix 系统上设置执行权限
        final result = await Process.run('chmod', ['+x', filePath]);
        if (result.exitCode != 0) {
          // Failed to set executable permission
        }
      }
    } catch (e) {
      // Failed to set executable permission
    }
  }
  
  static String _getPlatformFolder() {
    if (Platform.isMacOS) {
      return 'darwin'; // 使用 darwin 作为 macOS 的文件夹名
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isLinux) {
      return 'linux';
    }
    throw UnsupportedError('Unsupported platform');
  }
}
