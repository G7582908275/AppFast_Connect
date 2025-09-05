import 'dart:io';
import '../utils/logger.dart';

/// 进程检查服务
/// 用于检查应用是否已经在运行，实现单实例功能
class ProcessService {
  static const String _lockFileName = 'appfast_connect.lock';
  static File? _lockFile;
  static bool _isInitialized = false;

  /// 检查应用是否已经在运行
  /// 返回 true 表示已有实例在运行，false 表示没有
  static Future<bool> isAlreadyRunning() async {
    try {
      await Logger.logInfo('检查应用是否已在运行...');
      
      // 获取锁文件路径
      final lockFilePath = await _getLockFilePath();
      final lockFile = File(lockFilePath);
      
      if (await lockFile.exists()) {
        // 检查锁文件是否有效
        final isValid = await _validateLockFile(lockFile);
        if (isValid) {
          await Logger.logInfo('检测到应用已在运行，锁文件: $lockFilePath');
          return true;
        } else {
          // 锁文件无效，删除它
          await Logger.logInfo('发现无效锁文件，正在清理: $lockFilePath');
          await lockFile.delete();
        }
      }
      
      await Logger.logInfo('应用未在运行，可以启动新实例');
      return false;
    } catch (e) {
      await Logger.logError('检查进程状态时发生错误', e);
      // 发生错误时，为了安全起见，假设没有其他实例在运行
      return false;
    }
  }

  /// 创建锁文件，标记应用正在运行
  static Future<void> createLockFile() async {
    try {
      if (_isInitialized) return;
      
      await Logger.logInfo('创建应用锁文件...');
      
      final lockFilePath = await _getLockFilePath();
      final lockFile = File(lockFilePath);
      
      // 如果锁文件已存在，先删除
      if (await lockFile.exists()) {
        await lockFile.delete();
      }
      
      // 创建新的锁文件
      final lockData = {
        'pid': pid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'processName': Platform.resolvedExecutable,
      };
      
      await lockFile.writeAsString(lockData.toString());
      _lockFile = lockFile;
      _isInitialized = true;
      
      await Logger.logInfo('应用锁文件创建成功: $lockFilePath');
    } catch (e) {
      await Logger.logError('创建锁文件失败', e);
      _isInitialized = false;
    }
  }

  /// 删除锁文件，标记应用已退出
  static Future<void> removeLockFile() async {
    try {
      if (!_isInitialized || _lockFile == null) return;
      
      await Logger.logInfo('删除应用锁文件...');
      
      if (await _lockFile!.exists()) {
        await _lockFile!.delete();
        await Logger.logInfo('应用锁文件删除成功');
      }
      
      _lockFile = null;
      _isInitialized = false;
    } catch (e) {
      await Logger.logError('删除锁文件失败', e);
    }
  }

  /// 获取锁文件路径
  static Future<String> _getLockFilePath() async {
    if (Platform.isWindows) {
      final tempDir = Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
      return '$tempDir\\$_lockFileName';
    } else {
      // macOS 和 Linux
      return '/tmp/$_lockFileName';
    }
  }

  /// 验证锁文件是否有效
  static Future<bool> _validateLockFile(File lockFile) async {
    try {
      final content = await lockFile.readAsString();
      
      // 简单的锁文件格式检查
      if (!content.contains('pid:') || !content.contains('timestamp:')) {
        await Logger.logWarning('锁文件格式无效');
        return false;
      }
      
      // 检查进程是否真的在运行
      final pidMatch = RegExp(r'pid: (\d+)').firstMatch(content);
      if (pidMatch == null) {
        await Logger.logWarning('无法从锁文件解析PID');
        return false;
      }
      
      final pid = int.tryParse(pidMatch.group(1)!);
      if (pid == null) {
        await Logger.logWarning('锁文件中的PID无效');
        return false;
      }
      
      // 检查进程是否真的存在
      final isProcessRunning = await _isProcessRunning(pid);
      if (!isProcessRunning) {
        await Logger.logInfo('锁文件中的进程已不存在，PID: $pid');
        return false;
      }
      
      await Logger.logInfo('锁文件有效，进程正在运行，PID: $pid');
      return true;
    } catch (e) {
      await Logger.logError('验证锁文件时发生错误', e);
      return false;
    }
  }

  /// 检查指定PID的进程是否在运行
  static Future<bool> _isProcessRunning(int pid) async {
    try {
      if (Platform.isWindows) {
        // Windows: 使用tasklist命令
        final result = await Process.run('tasklist', ['/FI', 'PID eq $pid']);
        return result.exitCode == 0 && result.stdout.toString().contains(pid.toString());
      } else {
        // macOS 和 Linux: 使用kill命令检查进程
        final result = await Process.run('kill', ['-0', pid.toString()]);
        return result.exitCode == 0;
      }
    } catch (e) {
      await Logger.logError('检查进程状态时发生错误，PID: $pid', e);
      return false;
    }
  }

  /// 尝试激活已存在的应用实例
  /// 通过发送信号或使用平台特定的方法
  static Future<bool> activateExistingInstance() async {
    try {
      await Logger.logInfo('尝试激活已存在的应用实例...');
      
      if (Platform.isWindows) {
        return await _activateWindowsInstance();
      } else if (Platform.isMacOS) {
        return await _activateMacOSInstance();
      } else if (Platform.isLinux) {
        return await _activateLinuxInstance();
      }
      
      return false;
    } catch (e) {
      await Logger.logError('激活已存在实例时发生错误', e);
      return false;
    }
  }

  /// Windows平台激活已存在实例
  static Future<bool> _activateWindowsInstance() async {
    try {
      // Windows: 尝试通过窗口标题查找并激活窗口
      final result = await Process.run('powershell', [
        '-Command',
        r'Get-Process | Where-Object {$_.ProcessName -like "*appfast*" -or $_.ProcessName -like "*flutter*"} | ForEach-Object { [Microsoft.VisualBasic.Interaction]::AppActivate($_.Id) }'
      ]);
      
      return result.exitCode == 0;
    } catch (e) {
      await Logger.logError('Windows激活实例失败', e);
      return false;
    }
  }

  /// macOS平台激活已存在实例
  static Future<bool> _activateMacOSInstance() async {
    try {
      // macOS: 使用osascript激活应用
      final result = await Process.run('osascript', [
        '-e',
        'tell application "System Events" to set frontmost of first process whose name contains "appfast" to true'
      ]);
      
      return result.exitCode == 0;
    } catch (e) {
      await Logger.logError('macOS激活实例失败', e);
      return false;
    }
  }

  /// Linux平台激活已存在实例
  static Future<bool> _activateLinuxInstance() async {
    try {
      // Linux: 尝试使用wmctrl激活窗口
      final result = await Process.run('wmctrl', ['-a', 'appfast']);
      
      if (result.exitCode != 0) {
        // 如果wmctrl不可用，尝试使用xdotool
        final result2 = await Process.run('xdotool', ['search', '--name', 'appfast', 'windowactivate']);
        return result2.exitCode == 0;
      }
      
      return result.exitCode == 0;
    } catch (e) {
      await Logger.logError('Linux激活实例失败', e);
      return false;
    }
  }

  /// 获取当前进程的PID
  static int get pid {
    try {
      if (Platform.isWindows) {
        // Windows: 使用GetCurrentProcessId
        final result = Process.runSync('powershell', ['-Command', '[System.Diagnostics.Process]::GetCurrentProcess().Id']);
        return int.tryParse(result.stdout.toString().trim()) ?? 0;
      } else {
        // macOS 和 Linux: 使用getpid系统调用
        final result = Process.runSync('sh', ['-c', 'echo \$PPID']);
        return int.tryParse(result.stdout.toString().trim()) ?? 0;
      }
    } catch (e) {
      return 0;
    }
  }
}
