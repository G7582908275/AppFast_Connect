import 'dart:io';
import 'dart:async';
import '../utils/logger.dart';
import '../utils/platform_utils.dart';

class ProcessCleanupService {
  static const String _coreProcessName = 'core';
  static const String _coreProcessNameWindows = 'core.exe';
  static const String _appfastConnectPath = 'appfast_connect';
  
  // 回调函数，用于断开VPN连接
  static Function? _disconnectCallback;
  
  /// 设置断开连接的回调函数
  static void setDisconnectCallback(Function callback) {
    _disconnectCallback = callback;
  }
  
  /// 彻底清理所有core进程（多次尝试确保清理完成）
  static Future<void> thoroughCleanup() async {
    await Logger.logInfo('开始彻底清理AppFast Connect相关进程...');
    
    // 首先尝试优雅地断开VPN连接
    await _gracefulDisconnect();
    
    // 最多尝试5次清理（增加尝试次数）
    for (int attempt = 1; attempt <= 5; attempt++) {
      await Logger.logInfo('第 $attempt 次清理尝试...');
      
      // 获取当前运行的AppFast Connect相关进程
      final pids = await getAppFastConnectProcessPIDs();
      if (pids.isEmpty) {
        await Logger.logInfo('没有发现AppFast Connect相关进程，清理完成');
        break;
      }
      
      await Logger.logInfo('发现 ${pids.length} 个AppFast Connect相关进程: ${pids.join(', ')}');
      
      // 逐个结束进程
      for (final pid in pids) {
        final success = await killProcessByPID(pid);
        if (success) {
          await Logger.logInfo('成功结束进程 PID: $pid');
        } else {
          await Logger.logWarning('结束进程 PID: $pid 失败');
        }
      }
      
      // 等待更长时间让进程完全结束
      await Future.delayed(Duration(seconds: 1));
      
      // 检查是否还有进程在运行
      final stillRunning = await hasAppFastConnectProcessesRunning();
      if (!stillRunning) {
        await Logger.logInfo('所有AppFast Connect相关进程已成功清理');
        break;
      } else {
        await Logger.logWarning('第 $attempt 次清理后仍有AppFast Connect相关进程在运行');
        if (attempt < 5) {
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
    
    // 最终检查
    final finalCheck = await hasAppFastConnectProcessesRunning();
    if (finalCheck) {
      await Logger.logError('彻底清理后仍有AppFast Connect相关进程在运行，尝试最后的强制清理');
      await _finalForceCleanup();
    } else {
      await Logger.logInfo('彻底清理完成，所有AppFast Connect相关进程已结束');
    }
    
    // 清理临时文件
    await _cleanupTempFiles();
    
    await Logger.logInfo('彻底清理完成');
  }
  
  /// 优雅地断开VPN连接
  static Future<void> _gracefulDisconnect() async {
    try {
      await Logger.logInfo('尝试优雅断开VPN连接...');
      
      // 调用VPN服务的断开方法
      // 这样可以确保VPN进程被正确终止
      await _disconnectVPNService();
      
    } catch (e) {
      await Logger.logWarning('优雅断开VPN连接失败，将强制清理: $e');
    }
  }
  
  /// 调用VPN服务断开连接
  static Future<void> _disconnectVPNService() async {
    try {
      await Logger.logInfo('调用VPN服务断开连接...');
      
      // 使用回调函数调用VPN服务断开连接
      if (_disconnectCallback != null) {
        await _disconnectCallback!();
        await Logger.logInfo('VPN服务断开连接成功');
      } else {
        await Logger.logWarning('没有设置断开连接回调函数');
      }
    } catch (e) {
      await Logger.logError('调用VPN服务断开连接时发生错误: $e');
    }
  }
  
  /// 最后的强制清理（使用更激进的方法）
  static Future<void> _finalForceCleanup() async {
    await Logger.logInfo('执行最后的强制清理...');
    
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        // 使用更激进的清理方法
        final result = await Process.run(
          'pkill',
          ['-9', '-f', 'core'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          await Logger.logInfo('最后的强制清理成功');
        } else {
          await Logger.logWarning('最后的强制清理返回退出码: ${result.exitCode}');
        }
        
        // 额外检查：使用ps命令查找并结束进程
        await _killProcessesByPS();
        
      } else if (Platform.isWindows) {
        // Windows: 使用更激进的taskkill
        final result = await Process.run(
          'taskkill',
          ['/F', '/IM', _coreProcessNameWindows],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          await Logger.logInfo('最后的强制清理成功');
        } else {
          await Logger.logWarning('最后的强制清理返回退出码: ${result.exitCode}');
        }
      }
    } catch (e) {
      await Logger.logError('最后的强制清理时发生错误: $e');
    }
  }
  
  /// 使用ps命令查找并结束进程（Unix系统）
  static Future<void> _killProcessesByPS() async {
    try {
      await Logger.logInfo('使用ps命令查找并结束进程...');
      
      final result = await Process.run(
        'ps',
        ['aux'],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains(_coreProcessName) && line.contains(_appfastConnectPath)) {
            // 提取PID
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length > 1) {
              final pid = parts[1];
              if (int.tryParse(pid) != null) {
                await Logger.logInfo('发现进程，尝试结束 PID: $pid');
                await killProcessByPID(pid);
              }
            }
          }
        }
      }
    } catch (e) {
      await Logger.logError('使用ps命令查找进程时发生错误: $e');
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
      await Logger.logInfo('Windows平台：开始强制结束AppFast Connect相关进程...');
      
      // 获取AppFast Connect相关的core.exe进程PID
      final pids = await getAppFastConnectProcessPIDs();
      if (pids.isEmpty) {
        await Logger.logInfo('Windows平台：没有找到AppFast Connect相关进程需要结束');
        return;
      }
      
      await Logger.logInfo('Windows平台：发现 ${pids.length} 个AppFast Connect相关进程: ${pids.join(', ')}');
      
      // 逐个结束进程
      for (final pid in pids) {
        final result = await Process.run(
          'taskkill',
          ['/F', '/PID', pid],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          await Logger.logInfo('Windows平台：成功结束进程 PID: $pid');
        } else {
          await Logger.logWarning('Windows平台：结束进程 PID: $pid 失败，退出码: ${result.exitCode}');
        }
      }
      
      await Logger.logInfo('Windows平台：AppFast Connect相关进程清理完成');
    } catch (e) {
      await Logger.logError('Windows平台：强制结束AppFast Connect相关进程时发生错误: $e');
    }
  }
  
  /// macOS平台强制结束core进程
  static Future<void> _killCoreProcessesMacOS() async {
    try {
      await Logger.logInfo('macOS平台：开始强制结束AppFast Connect相关进程...');
      
      // 使用pkill命令强制结束所有core进程，但只针对appfast_connect目录下的进程
      final result = await Process.run(
        'pkill',
        ['-9', '-f', '$_appfastConnectPath.*$_coreProcessName'],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        await Logger.logInfo('macOS平台：成功结束AppFast Connect相关进程');
      } else if (result.exitCode == 1) {
        await Logger.logInfo('macOS平台：没有找到AppFast Connect相关进程需要结束');
      } else {
        await Logger.logWarning('macOS平台：结束AppFast Connect相关进程时返回退出码: ${result.exitCode}');
        if (result.stderr.isNotEmpty) {
          await Logger.logWarning('macOS平台：错误信息: ${result.stderr}');
        }
      }
    } catch (e) {
      await Logger.logError('macOS平台：强制结束AppFast Connect相关进程时发生错误: $e');
    }
  }
  
  /// Linux平台强制结束core进程
  static Future<void> _killCoreProcessesLinux() async {
    try {
      await Logger.logInfo('Linux平台：开始强制结束AppFast Connect相关进程...');
      
      // 使用pkill命令强制结束所有core进程，但只针对appfast_connect目录下的进程
      final result = await Process.run(
        'pkill',
        ['-9', '-f', '$_appfastConnectPath.*$_coreProcessName'],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        await Logger.logInfo('Linux平台：成功结束AppFast Connect相关进程');
      } else if (result.exitCode == 1) {
        await Logger.logInfo('Linux平台：没有找到AppFast Connect相关进程需要结束');
      } else {
        await Logger.logWarning('Linux平台：结束AppFast Connect相关进程时返回退出码: ${result.exitCode}');
        if (result.stderr.isNotEmpty) {
          await Logger.logWarning('Linux平台：错误信息: ${result.stderr}');
        }
      }
    } catch (e) {
      await Logger.logError('Linux平台：强制结束AppFast Connect相关进程时发生错误: $e');
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
  
  /// 检查是否还有AppFast Connect相关进程在运行
  static Future<bool> hasAppFastConnectProcessesRunning() async {
    try {
      if (Platform.isWindows) {
        // Windows: 检查是否有core.exe进程，并且命令行包含appfast_connect路径
        final result = await Process.run(
          'wmic',
          ['process', 'where', 'name="$_coreProcessNameWindows"', 'get', 'processid,commandline'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          // 检查是否有包含appfast_connect路径的进程
          return output.contains(_appfastConnectPath);
        }
        return false;
      } else if (Platform.isMacOS || Platform.isLinux) {
        // Unix系统: 使用pgrep查找包含appfast_connect路径的core进程
        final result = await Process.run(
          'pgrep',
          ['-f', '$_appfastConnectPath.*$_coreProcessName'],
          runInShell: true,
        );
        return result.exitCode == 0;
      } else {
        return false;
      }
    } catch (e) {
      await Logger.logError('检查AppFast Connect相关进程状态时发生错误: $e');
      return false;
    }
  }
  
  /// 验证进程是否属于AppFast Connect
  static Future<bool> _isAppFastConnectProcess(String pid) async {
    try {
      if (Platform.isWindows) {
        // Windows: 检查进程的命令行是否包含appfast_connect路径
        final result = await Process.run(
          'wmic',
          ['process', 'where', 'processid=$pid', 'get', 'commandline'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          return output.contains(_appfastConnectPath) && output.contains(_coreProcessNameWindows);
        }
        return false;
      } else if (Platform.isMacOS || Platform.isLinux) {
        // Unix系统: 检查进程的命令行是否包含appfast_connect路径
        final result = await Process.run(
          'ps',
          ['-p', pid, '-o', 'args='],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          return output.contains(_appfastConnectPath) && output.contains(_coreProcessName);
        }
        return false;
      }
      return false;
    } catch (e) {
      await Logger.logWarning('验证进程 $pid 时发生错误: $e');
      return false;
    }
  }
  
  /// 获取所有AppFast Connect相关进程的PID列表（带验证）
  static Future<List<String>> getAppFastConnectProcessPIDs() async {
    final pids = <String>[];
    try {
      if (Platform.isWindows) {
        // Windows: 获取core.exe进程，但只返回包含appfast_connect路径的进程
        final result = await Process.run(
          'wmic',
          ['process', 'where', 'name="$_coreProcessNameWindows"', 'get', 'processid,commandline'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.contains(_appfastConnectPath) && line.contains(_coreProcessNameWindows)) {
              // 提取PID
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.isNotEmpty) {
                final pid = parts[0].trim();
                if (pid.isNotEmpty && int.tryParse(pid) != null) {
                  // 额外验证进程是否真的属于AppFast Connect
                  final isValid = await _isAppFastConnectProcess(pid);
                  if (isValid) {
                    pids.add(pid);
                  } else {
                    await Logger.logWarning('跳过不属于AppFast Connect的进程 PID: $pid');
                  }
                }
              }
            }
          }
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        // Unix系统: 获取包含appfast_connect路径的core进程PID
        final result = await Process.run(
          'pgrep',
          ['-f', '$_appfastConnectPath.*$_coreProcessName'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          if (output.isNotEmpty) {
            final candidatePids = output.split('\n').where((pid) => pid.trim().isNotEmpty);
            for (final pid in candidatePids) {
              // 额外验证进程是否真的属于AppFast Connect
              final isValid = await _isAppFastConnectProcess(pid);
              if (isValid) {
                pids.add(pid);
              } else {
                await Logger.logWarning('跳过不属于AppFast Connect的进程 PID: $pid');
              }
            }
          }
        }
      }
    } catch (e) {
      await Logger.logError('获取AppFast Connect相关进程PID列表时发生错误: $e');
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
  
  /// 调试方法：列出所有相关进程的详细信息
  static Future<void> debugListProcesses() async {
    await Logger.logInfo('=== 调试：列出所有相关进程信息 ===');
    
    try {
      if (Platform.isWindows) {
        await Logger.logInfo('Windows平台：搜索所有core.exe进程...');
        final result = await Process.run(
          'wmic',
          ['process', 'where', 'name="$_coreProcessNameWindows"', 'get', 'processid,commandline'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.trim().isNotEmpty && !line.contains('ProcessId')) {
              await Logger.logInfo('发现进程: $line');
            }
          }
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        await Logger.logInfo('Unix平台：搜索所有core进程...');
        final result = await Process.run(
          'ps',
          ['aux'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.contains(_coreProcessName)) {
              await Logger.logInfo('发现进程: $line');
            }
          }
        }
      }
    } catch (e) {
      await Logger.logError('调试进程列表时发生错误: $e');
    }
    
    await Logger.logInfo('=== 调试结束 ===');
  }
}
