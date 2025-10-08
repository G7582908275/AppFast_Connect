
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

class PlatformUtils {
  static bool get isMacOS => Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  
  // 缓存已释放的可执行文件路径
  static String? _cachedExecutablePath;
  
  // 核心文件下载URL映射
  static const Map<String, String> _coreDownloadUrls = {
    'windows_x64': 'https://www.widewired.com/static/core/appfast-core_windows_amd64.exe',
    'windows_arm64': 'https://www.widewired.com/static/core/appfast-core_windows_arm64.exe',
    'darwin_x64': 'https://www.widewired.com/static/core/appfast-core_darwin_amd64',
    'darwin_arm64': 'https://www.widewired.com/static/core/appfast-core_darwin_arm64',
    'linux_x64': 'https://www.widewired.com/static/core/appfast-core_linux_amd64',
    'linux_arm64': 'https://www.widewired.com/static/core/appfast-core_linux_arm64',
  };
  
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
  
  /// 获取平台和架构组合键名
  static String get platformArchKey {
    String platform;
    if (Platform.isWindows) {
      platform = 'windows';
    } else if (Platform.isMacOS) {
      platform = 'darwin';
    } else if (Platform.isLinux) {
      platform = 'linux';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
    
    String arch = architecture.toLowerCase();
    if (arch == 'x64') arch = 'x64';
    if (arch == 'arm64') arch = 'arm64';
    
    return '${platform}_$arch';
  }
  
  /// 获取当前平台对应的下载URL
  static String? get downloadUrl {
    final url = _coreDownloadUrls[platformArchKey];
    if (url != null) {
      Logger.logInfo('检测到平台架构: ${platformArchKey}');
      Logger.logInfo('对应下载URL: $url');
    } else {
      Logger.logError('不支持的平台架构: ${platformArchKey}');
    }
    return url;
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

  /// 获取远程文件的ETag用于版本检查
  static Future<String?> getRemoteFileETag(String url) async {
    try {
      await Logger.logInfo('检查远程文件版本: $url');
      final response = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final etag = response.headers['etag'];
        await Logger.logInfo('远程文件ETag: $etag');
        return etag;
      } else {
        await Logger.logWarning('无法获取远程文件信息，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      await Logger.logError('获取远程文件版本失败', e);
      return null;
    }
  }
  
  /// 获取本地缓存的版本信息
  static Future<String?> getUserPreferenceVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('core_version');
    } catch (e) {
      await Logger.logError('获取本地版本信息失败', e);
      return null;
    }
  }
  
  /// 保存版本信息到本地
  static Future<void> setUserPreferenceVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('core_version', version);
      await Logger.logInfo('版本信息已保存: $version');
    } catch (e) {
      await Logger.logError('保存版本信息失败', e);
    }
  }
  
  
  
  /// 检查并更新核心文件（如果有新版本）
  static Future<bool> checkAndUpdateCoreFile() async {
    try {
      final downloadUrl = PlatformUtils.downloadUrl;
      if (downloadUrl == null) {
        await Logger.logError('不支持的平台或架构: ${PlatformUtils.platformArchKey}');
        return false;
      }
      
      // 获取远程版本
      final remoteVersion = await getRemoteFileETag(downloadUrl);
      if (remoteVersion == null) {
        await Logger.logWarning('无法获取远程版本，跳过更新检查');
        return true; // 继续使用现有文件
      }
      
      // 获取本地版本
      final localVersion = await getUserPreferenceVersion();
      
      if (localVersion == null || localVersion != remoteVersion) {
        await Logger.logInfo('发现新版本，开始下载更新');
        await Logger.logInfo('本地版本: $localVersion');
        await Logger.logInfo('远程版本: $remoteVersion');
        
        return await downloadAndExtractCoreFile(downloadUrl);
      } else {
        await Logger.logInfo('核心文件已是最新版本，版本: $localVersion');
        
        // 即使版本相同，也要验证文件是否存在
        final fileName = libraryFileName;
        String tempDirPath;
        if (Platform.isMacOS) {
          tempDirPath = '/tmp';
        } else if (Platform.isWindows) {
          tempDirPath = Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
        } else if (Platform.isLinux) {
          tempDirPath = '/tmp';
        } else {
          return false;
        }
        
        final filePath = '$tempDirPath/appfast_connect/$fileName';
        final file = File(filePath);
        
        if (await file.exists()) {
          await Logger.logInfo('本地文件存在: $filePath');
          return true;
        } else {
          await Logger.logInfo('本地文件不存在，需要重新下载: $filePath');
          return await downloadAndExtractCoreFile(downloadUrl);
        }
      }
      
    } catch (e) {
      await Logger.logError('检查更新失败', e);
      return false;
    }
  }
  
  /// 下载核心文件（新URL提供直接可执行文件，无需解压）
  static Future<bool> downloadAndExtractCoreFile(String url) async {
    try {
      // 获取临时目录结构
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
      
      // 创建最终目标目录
      final executiveDir = Directory('${tempDirPath}/appfast_connect');
      await executiveDir.create(recursive: true);
      
      // 获取最终可执行文件路径
      final fileName = libraryFileName;
      final finalPath = '${executiveDir.path}/$fileName';
      
      // 直接下载到最终位置（新URL提供的就是可执行文件）
      await Logger.logInfo('下载核心文件: $url -> $finalPath');
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(minutes: 5));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final file = File(finalPath);
        
        // 写入文件
        await file.writeAsBytes(bytes);
        
        // 设置执行权限
        await _ensureExecutablePermission(finalPath);
        
        // 保存版本信息
        final etag = response.headers['etag'];
        if (etag != null) {
          await setUserPreferenceVersion(etag);
        }
        
        final fileSize = await file.length();
        await Logger.logInfo('核心文件下载完成: $finalPath ($fileSize bytes)');
        
        return true;
      } else {
        await Logger.logError('下载失败，状态码: ${response.statusCode}', null);
        return false;
      }
      
    } catch (e) {
      await Logger.logError('下载核心文件失败', e);
      return false;
    }
  }

  static Future<String> getExecutablePath() async {
    try {
      // 如果已经缓存了路径，检查文件是否仍然存在
      if (_cachedExecutablePath != null) {
        final cachedFile = File(_cachedExecutablePath!);
        if (await cachedFile.exists()) {
          await Logger.logInfo('使用缓存的可执行文件路径: $_cachedExecutablePath');
          
          // 检查是否有新版本（后台进行，不影响当前使用）
          checkAndUpdateCoreFile().then((hasUpdate) {
            if (hasUpdate) {
              Logger.logInfo('核心文件已更新，下次启动将使用新版本');
            }
          });
          
          return _cachedExecutablePath!;
        } else {
          await Logger.logInfo('缓存的可执行文件不存在，重新获取: $_cachedExecutablePath');
          _cachedExecutablePath = null;
        }
      }
      
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
        throw UnsupportedError('Unsupported platform');
      }
      
      final tempDir = Directory(tempDirPath);
      final executableDir = Directory('${tempDir.path}/appfast_connect');
      
      // 确保目录存在
      if (!await executableDir.exists()) {
        await executableDir.create(recursive: true);
      }
      
      final executablePath = '${executableDir.path}/$fileName';
      
      // 首先尝试检查并更新核心文件
      await Logger.logInfo('检查核心文件更新...');
      final updateSuccess = await checkAndUpdateCoreFile();
      
      if (updateSuccess) {
        final downloadedFile = File(executablePath);
        if (await downloadedFile.exists()) {
          // 使用下载的核心文件
          await Logger.logInfo('使用更新后的核心文件: $executablePath');
          _cachedExecutablePath = executablePath;
          return executablePath;
        }
      }
      
      // 如果更新失败或下载的文件不存在，回退到assets
      await Logger.logWarning('更新失败或文件不存在，回退到本地assets资源');
      
      // 每次启动都删除现有文件并重新复制
      final file = File(executablePath);
      if (await file.exists()) {
        await Logger.logInfo('删除现有可执行文件: $executablePath');
        await file.delete();
      }
      
      // 从assets复制文件并重命名
      await Logger.logInfo('正在释放资源文件: ${libraryPath} -> $executablePath');
      
      try {
        // 使用新的加载方法
        final bytes = await loadAssetBytes(libraryPath);
        
        // 写入文件
        await file.writeAsBytes(bytes);
        
        // 设置执行权限
        await _ensureExecutablePermission(executablePath);
        
        final finalSize = await file.length();
        await Logger.logInfo('资源文件释放完成: $executablePath ($finalSize bytes)');
        
        // 缓存路径
        _cachedExecutablePath = executablePath;
        
        return executablePath;
      } catch (e) {
        await Logger.logError('从assets释放文件失败，尝试使用现有文件', e);
        
        // 如果存在现有文件，直接使用
        if (await file.exists()) {
          await Logger.logInfo('使用现有可执行文件: $executablePath');
          _cachedExecutablePath = executablePath;
          return executablePath;
        } else {
          rethrow;
        }
      }
      
    } catch (e) {
      await Logger.logError('获取可执行文件失败', e);
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
      
      // 清理缓存
      _cachedExecutablePath = null;
      await Logger.logInfo('已清理可执行文件路径缓存');
    } catch (e) {
      await Logger.logError('清理临时文件时发生错误', e);
    }
  }
  
  /// 清理缓存（不删除文件）
  static void clearCache() {
    _cachedExecutablePath = null;
  }
  
  /// 手动检查并强制更新核心文件
  static Future<bool> forceUpdateCoreFile() async {
    try {
      await Logger.logInfo('手动强制更新核心文件...');
      
      final downloadUrl = PlatformUtils.downloadUrl;
      if (downloadUrl == null) {
        await Logger.logError('不支持的平台或架构: ${PlatformUtils.platformArchKey}');
        return false;
      }
      
      await Logger.logInfo('强制下载更新: $downloadUrl');
      final success = await downloadAndExtractCoreFile(downloadUrl);
      
      if (success) {
        await Logger.logInfo('强制更新成功');
        // 清理缓存，强制下次使用新文件
        _cachedExecutablePath = null;
      } else {
        await Logger.logError('强制更新失败');
      }
      
      return success;
    } catch (e) {
      await Logger.logError('强制更新时发生错误', e);
      return false;
    }
  }
  
  /// 获取当前核心文件版本信息
  static Future<Map<String, String>> getCoreVersionInfo() async {
    final localVersion = await getUserPreferenceVersion();
    final downloadUrl = PlatformUtils.downloadUrl;
    String? remoteVersion;
    
    if (downloadUrl != null) {
      remoteVersion = await getRemoteFileETag(downloadUrl);
    }
    
    return {
      'local': localVersion ?? '未知',
      'remote': remoteVersion ?? '未知',
      'platform': platformArchKey,
      'downloadUrl': downloadUrl ?? '不支持',
    };
  }
}
