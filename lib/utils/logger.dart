import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class Logger {
  static File? _logFile;
  static StreamController<String>? _logController;
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 根据平台选择日志目录
      String logDirPath;
      if (Platform.isWindows) {
        // Windows: 使用用户临时目录
        final tempDir = Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
        logDirPath = '$tempDir\\appfast_connect\\logs';
      } else if (Platform.isMacOS) {
        // macOS: 使用 /tmp 目录
        logDirPath = '/tmp/appfast_connect/logs';
      } else if (Platform.isLinux) {
        // Linux: 使用 /tmp 目录
        logDirPath = '/tmp/appfast_connect/logs';
      } else {
        // 默认使用当前目录
        logDirPath = './logs';
      }
      
      final logDir = Directory(logDirPath);
      
      // 确保日志目录存在
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // 创建日志文件
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _logFile = File('${logDir.path}${Platform.pathSeparator}app_$timestamp.log');
      
      // 创建流控制器用于实时日志
      _logController = StreamController<String>.broadcast();
      
      _initialized = true;
      
      // 写入启动信息
      await _writeLog('=== AppFast Connect 启动 ===');
      await _writeLog('日志文件路径: ${_logFile!.path}');
      await _writeLog('系统信息: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      await _writeLog('应用路径: ${Platform.resolvedExecutable}');
    } catch (e) {
      // 如果初始化失败，至少确保有基本的日志输出
      print('Logger初始化失败: $e');
    }
  }
  
  static Future<void> _writeLog(String message) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] $message';
      
      // 输出到控制台（开发时）
      if (kDebugMode) {
        print(logMessage);
      }
      
      // 写入日志文件
      if (_logFile != null) {
        await _logFile!.writeAsString('$logMessage\n', mode: FileMode.append);
      }
      
      // 发送到流（如果有监听器）
      _logController?.add(logMessage);
    } catch (e) {
      // 如果写入失败，至少输出到控制台
      print('日志写入失败: $e');
      print('原始消息: $message');
    }
  }
  
  static Future<void> log(String message) async {
    await _writeLog(message);
  }
  
  static Future<void> logError(String message, [dynamic error, StackTrace? stackTrace]) async {
    await _writeLog('ERROR: $message');
    if (error != null) {
      await _writeLog('错误详情: $error');
    }
    if (stackTrace != null) {
      await _writeLog('堆栈跟踪: $stackTrace');
    }
  }
  
  static Future<void> logInfo(String message) async {
    await _writeLog('INFO: $message');
  }
  
  static Future<void> logWarning(String message) async {
    await _writeLog('WARNING: $message');
  }
  
  static Future<void> logDebug(String message) async {
    if (kDebugMode) {
      await _writeLog('DEBUG: $message');
    }
  }
  
  static Stream<String> get logStream {
    return _logController?.stream ?? Stream.empty();
  }
  
  static Future<String?> getLogFilePath() async {
    return _logFile?.path;
  }
  
  static Future<void> clearLogs() async {
    try {
      // 根据平台选择日志目录
      String logDirPath;
      if (Platform.isWindows) {
        final tempDir = Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
        logDirPath = '$tempDir\\appfast_connect\\logs';
      } else if (Platform.isMacOS) {
        logDirPath = '/tmp/appfast_connect/logs';
      } else if (Platform.isLinux) {
        logDirPath = '/tmp/appfast_connect/logs';
      } else {
        logDirPath = './logs';
      }
      
      final logDir = Directory(logDirPath);
      
      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
      }
    } catch (e) {
      print('清理日志失败: $e');
    }
  }
}
