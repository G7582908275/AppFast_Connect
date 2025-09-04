import 'dart:io';
import 'dart:async';
import '../utils/logger.dart';
import '../utils/platform_utils.dart';

class ProcessCleanupService {
  static const String _coreProcessName = 'core';
  static const String _coreProcessNameWindows = 'core.exe';
  
  /// 彻底清理所有core进程（多次尝试确保清理完成）
  static Future<void> thoroughCleanup() async {
    await Logger.logInfo('开始彻底清理core进程...');
    
    // 首先尝试优雅地断开VPN连接
    await _gracefulDisconnect();
    
    // 最多尝试3次清理
    for (int attempt = 1; attempt <= 3; attempt++) {
      await Logger.logInfo('第 $attempt 次清理尝试...');
      
      // 获取当前运行的core进程
      final pids = await getCoreProcessPIDs();
      if (pids.isEmpty) {
        await Logger.logInfo('没有发现core进程，清理完成');
        break;
      }
      
      await Logger.logInfo('发现 ${pids.length} 个core进程: ${pids.join(', ')}');
      
      // 逐个结束进程
      for (final pid in pids) {
        final success = await killProcessByPID(pid);
        if (success) {
          await Logger.logInfo('成功结束进程 PID: $pid');
        } else {
          await Logger.logWarning('结束进程 PID: $pid 失败');
        }
      }
      
      // 等待一段时间让进程完全结束
      await Future.delayed(Duration(milliseconds: 500));
      
      // 检查是否还有进程在运行
      final stillRunning = await hasCoreProcessesRunning();
      if (!stillRunning) {
        await Logger.logInfo('所有core进程已成功清理');
        break;
      } else {
        await Logger.logWarning('第 $attempt 次清理后仍有core进程在运行');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }
    
    // 最终检查
    final finalCheck = await hasCoreProcessesRunning();
    if (finalCheck) {
      await Logger.logError('彻底清理后仍有core进程在运行');
    } else {
      await Logger.logInfo('彻底清理完成，所有core进程已结束');
    }
    
    // 清理临时文件
    await _cleanupTempFiles();
    
    await Logger.logInfo('彻底清理完成');
  }
  
  /// 优雅地断开VPN连接
  static Future<void> _gracefulDisconnect() async {
    try {
      // 这里可以调用VPN服务的断开方法
      // 但由于循环依赖问题，我们直接处理进程
      await Logger.logInfo('尝试优雅断开VPN连接...');
    } catch (e) {
      await Logger.logWarning('优雅断开VPN连接失败，将强制清理: $e');
    }
  }
  
  /// 强制结束所有core进程（旧方法，保留兼容性）
  static Future<void> _forceKillCoreProcesses() async {
    try {
      if (Platform.isWindows) {
        await _killCoreProcessesWindows();
      } else if (Platform.isMacOS) {
        await _killCoreProcessesMacOS();
      } else if (Platform.isLinux) {
        await _killCoreProcessesLinux();
      } else {
        await Logger.logWarning('不支持的平台，跳过进程清理');
      }
    } catch (e) {
      await Logger.logError('强制结束core进程失败: $e');
    }
  }
  
  /// Windows平台强制结束core进程
  static Future<void> _killCoreProcessesWindows() async {
    try {
      await Logger.logInfo('Windows平台：开始强制结束core进程...');
      
      // 使用taskkill命令强制结束所有core.exe进程
      final result = await Process.run(
        'taskkill',
        ['/F', '/IM', _coreProcessNameWindows],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        await Logger.logInfo('Windows平台：成功结束core进程');
      } else if (result.exitCode == 128) {
        await Logger.logInfo('Windows平台：没有找到core进程需要结束');
      } else {
        await Logger.logWarning('Windows平台：结束core进程时返回退出码: ${result.exitCode}');
        if (result.stderr.isNotEmpty) {
          await Logger.logWarning('Windows平台：错误信息: ${result.stderr}');
        }
      }
    } catch (e) {
      await Logger.logError('Windows平台：强制结束core进程时发生错误: $e');
    }
  }
  
  /// macOS平台强制结束core进程
  static Future<void> _killCoreProcessesMacOS() async {
    try {
      await Logger.logInfo('macOS平台：开始强制结束core进程...');
      
      // 使用pkill命令强制结束所有core进程
      final result = await Process.run(
        'pkill',
        ['-9', '-f', _coreProcessName],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        await Logger.logInfo('macOS平台：成功结束core进程');
      } else if (result.exitCode == 1) {
        await Logger.logInfo('macOS平台：没有找到core进程需要结束');
      } else {
        await Logger.logWarning('macOS平台：结束core进程时返回退出码: ${result.exitCode}');
        if (result.stderr.isNotEmpty) {
          await Logger.logWarning('macOS平台：错误信息: ${result.stderr}');
        }
      }
    } catch (e) {
      await Logger.logError('macOS平台：强制结束core进程时发生错误: $e');
    }
  }
  
  /// Linux平台强制结束core进程
  static Future<void> _killCoreProcessesLinux() async {
    try {
      await Logger.logInfo('Linux平台：开始强制结束core进程...');
      
      // 使用pkill命令强制结束所有core进程
      final result = await Process.run(
        'pkill',
        ['-9', '-f', _coreProcessName],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        await Logger.logInfo('Linux平台：成功结束core进程');
      } else if (result.exitCode == 1) {
        await Logger.logInfo('Linux平台：没有找到core进程需要结束');
      } else {
        await Logger.logWarning('Linux平台：结束core进程时返回退出码: ${result.exitCode}');
        if (result.stderr.isNotEmpty) {
          await Logger.logWarning('Linux平台：错误信息: ${result.stderr}');
        }
      }
    } catch (e) {
      await Logger.logError('Linux平台：强制结束core进程时发生错误: $e');
    }
  }
  
  /// 清理临时文件
  static Future<void> _cleanupTempFiles() async {
    try {
      await Logger.logInfo('开始清理临时文件...');
      
      // 调用PlatformUtils的清理方法
      await PlatformUtils.cleanupExecutableFiles();
      
      // 清理日志文件（可选）
      await _cleanupLogFiles();
      
      await Logger.logInfo('临时文件清理完成');
    } catch (e) {
      await Logger.logError('清理临时文件时发生错误: $e');
    }
  }
  
  /// 清理日志文件
  static Future<void> _cleanupLogFiles() async {
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
        return;
      }
      
      final logDir = Directory(logDirPath);
      if (await logDir.exists()) {
        // 只删除超过7天的日志文件
        final now = DateTime.now();
        final files = await logDir.list().toList();
        
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            final age = now.difference(stat.modified);
            if (age.inDays > 7) {
              await file.delete();
              await Logger.logInfo('删除旧日志文件: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      await Logger.logWarning('清理日志文件时发生错误: $e');
    }
  }
  
  /// 检查是否还有core进程在运行
  static Future<bool> hasCoreProcessesRunning() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run(
          'tasklist',
          ['/FI', 'IMAGENAME eq $_coreProcessNameWindows'],
          runInShell: true,
        );
        return result.stdout.toString().contains(_coreProcessNameWindows);
      } else if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run(
          'pgrep',
          ['-f', _coreProcessName],
          runInShell: true,
        );
        return result.exitCode == 0;
      } else {
        return false;
      }
    } catch (e) {
      await Logger.logError('检查core进程状态时发生错误: $e');
      return false;
    }
  }
  
  /// 获取所有core进程的PID列表
  static Future<List<String>> getCoreProcessPIDs() async {
    final pids = <String>[];
    try {
      if (Platform.isWindows) {
        final result = await Process.run(
          'tasklist',
          ['/FI', 'IMAGENAME eq $_coreProcessNameWindows', '/FO', 'CSV'],
          runInShell: true,
        );
        
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains(_coreProcessNameWindows) && !line.contains('Image Name')) {
            final parts = line.split(',');
            if (parts.length > 1) {
              final pid = parts[1].replaceAll('"', '').trim();
              if (pid.isNotEmpty && int.tryParse(pid) != null) {
                pids.add(pid);
              }
            }
          }
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run(
          'pgrep',
          ['-f', _coreProcessName],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          if (output.isNotEmpty) {
            pids.addAll(output.split('\n').where((pid) => pid.trim().isNotEmpty));
          }
        }
      }
    } catch (e) {
      await Logger.logError('获取core进程PID列表时发生错误: $e');
    }
    return pids;
  }
  
  /// 强制结束指定PID的进程
  static Future<bool> killProcessByPID(String pid) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run(
          'taskkill',
          ['/F', '/PID', pid],
          runInShell: true,
        );
        return result.exitCode == 0;
      } else if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run(
          'kill',
          ['-9', pid],
          runInShell: true,
        );
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      await Logger.logError('结束进程PID $pid 时发生错误: $e');
      return false;
    }
  }
  
  /// 立即强制清理（用于手动调用）
  static Future<void> forceCleanup() async {
    await Logger.logInfo('手动触发强制进程清理...');
    await thoroughCleanup();
  }
}
