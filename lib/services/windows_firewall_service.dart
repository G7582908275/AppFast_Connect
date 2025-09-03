import 'dart:io';
import '../utils/logger.dart';
import '../utils/platform_utils.dart';

class WindowsFirewallService {
  static const String _ruleName = 'appfast_core';
  
  /// 检查是否为Windows平台
  static bool get _isWindows => PlatformUtils.isWindows;
  
  /// 获取core.exe的路径
  static String get _exePath {
    // 使用临时目录路径，与VPN服务保持一致
    final tempDir = Directory.systemTemp.path;
    return '$tempDir/appfast_connect/core.exe';
  }
  
  /// 获取安全的工作目录（避免UNC路径）
  static String get _safeWorkingDirectory {
    // 检查当前工作目录是否为UNC路径
    final currentDir = Directory.current.path;
    if (currentDir.startsWith('\\\\')) {
      // 如果是UNC路径，使用系统临时目录
      return Directory.systemTemp.path;
    }
    return currentDir;
  }
  
  /// 检查管理员权限
  static Future<bool> _checkAdminPrivileges() async {
    try {
      final result = await Process.run(
        'net',
        ['session'],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      await Logger.logError('检查管理员权限时发生错误', e);
      return false;
    }
  }
  
  /// 检查core.exe文件是否存在
  static Future<bool> _checkCoreExeExists() async {
    try {
      final file = File(_exePath);
      final exists = await file.exists();
      await Logger.logInfo('检查core.exe文件: $_exePath - 存在: $exists');
      if (exists) {
        final size = await file.length();
        await Logger.logInfo('core.exe文件大小: $size bytes');
      }
      return exists;
    } catch (e) {
      await Logger.logError('检查core.exe文件时发生错误', e);
      return false;
    }
  }
  
  /// 添加防火墙规则
  static Future<bool> addFirewallRules() async {
    if (!_isWindows) {
      await Logger.logInfo('非Windows平台，跳过防火墙规则添加');
      return true;
    }
    
    try {
      await Logger.logInfo('开始添加Windows防火墙规则');
      
      // 检查管理员权限
      final hasAdmin = await _checkAdminPrivileges();
      await Logger.logInfo('管理员权限检查: $hasAdmin');
      
      if (!hasAdmin) {
        await Logger.logError('没有管理员权限，无法添加防火墙规则');
        return false;
      }
      
      // 检查core.exe文件
      final coreExists = await _checkCoreExeExists();
      if (!coreExists) {
        await Logger.logError('core.exe文件不存在，无法添加防火墙规则');
        return false;
      }
      
      // 记录工作目录信息
      final workingDir = _safeWorkingDirectory;
      await Logger.logInfo('使用工作目录: $workingDir');
      
      // 测试netsh命令是否可用
      await _testNetshCommand(workingDir);
      
      // 删除旧规则（如果存在）
      await _deleteExistingRule(workingDir);
      
      // 添加入站规则
      final inboundResult = await _addRule('in', workingDir);
      if (!inboundResult) {
        await Logger.logError('添加入站防火墙规则失败');
        return false;
      }
      
      // 添加出站规则
      final outboundResult = await _addRule('out', workingDir);
      if (!outboundResult) {
        await Logger.logError('添加出站防火墙规则失败');
        return false;
      }
      
      await Logger.logInfo('Windows防火墙规则添加成功: $_ruleName');
      return true;
      
    } catch (e) {
      await Logger.logError('添加防火墙规则时发生错误', e);
      return false;
    }
  }
  
  /// 测试netsh命令
  static Future<void> _testNetshCommand(String workingDir) async {
    try {
      await Logger.logInfo('测试netsh命令...');
      
      final result = await Process.run(
        'netsh',
        ['advfirewall', 'show', 'allprofiles'],
        runInShell: true,
        workingDirectory: workingDir,
      );
      
      await Logger.logInfo('netsh测试结果 - 退出码: ${result.exitCode}');
      if (result.stdout.isNotEmpty) {
        await Logger.logInfo('netsh测试输出: ${result.stdout.toString().substring(0, result.stdout.toString().length > 200 ? 200 : result.stdout.toString().length)}...');
      }
      if (result.stderr.isNotEmpty) {
        await Logger.logError('netsh测试错误: ${result.stderr}');
      }
    } catch (e) {
      await Logger.logError('测试netsh命令时发生错误', e);
    }
  }
  
  /// 删除现有的防火墙规则
  static Future<bool> _deleteExistingRule(String workingDir) async {
    try {
      await Logger.logInfo('尝试删除现有防火墙规则: $_ruleName');
      
      final result = await Process.run(
        'netsh',
        ['advfirewall', 'firewall', 'delete', 'rule', 'name=$_ruleName'],
        runInShell: true,
        workingDirectory: workingDir,
      );
      
      await Logger.logInfo('删除规则结果 - 退出码: ${result.exitCode}');
      if (result.stdout.isNotEmpty) {
        await Logger.logInfo('删除规则输出: ${result.stdout}');
      }
      if (result.stderr.isNotEmpty) {
        await Logger.logInfo('删除规则错误: ${result.stderr}');
      }
      
      if (result.exitCode == 0) {
        await Logger.logInfo('成功删除现有防火墙规则: $_ruleName');
      } else {
        await Logger.logInfo('删除现有防火墙规则时返回非零退出码: ${result.exitCode}');
      }
      
      return true;
    } catch (e) {
      await Logger.logWarning('删除现有防火墙规则时发生错误: $e');
      return false;
    }
  }
  
  /// 添加防火墙规则
  static Future<bool> _addRule(String direction, String workingDir) async {
    try {
      final args = [
        'advfirewall',
        'firewall',
        'add',
        'rule',
        'name=$_ruleName',
        'dir=$direction',
        'action=allow',
        'program=$_exePath',
        'enable=yes'
      ];
      
      await Logger.logInfo('执行防火墙命令: netsh ${args.join(' ')}');
      
      final result = await Process.run(
        'netsh',
        args,
        runInShell: true,
        workingDirectory: workingDir,
      );
      
      await Logger.logInfo('添加${direction == 'in' ? '入站' : '出站'}规则结果 - 退出码: ${result.exitCode}');
      if (result.stdout.isNotEmpty) {
        await Logger.logInfo('添加规则输出: ${result.stdout}');
      }
      if (result.stderr.isNotEmpty) {
        await Logger.logError('添加规则错误: ${result.stderr}');
      }
      
      if (result.exitCode == 0) {
        await Logger.logInfo('成功添加${direction == 'in' ? '入站' : '出站'}防火墙规则');
        return true;
      } else {
        await Logger.logError('添加${direction == 'in' ? '入站' : '出站'}防火墙规则失败，退出码: ${result.exitCode}');
        return false;
      }
    } catch (e) {
      await Logger.logError('添加${direction == 'in' ? '入站' : '出站'}防火墙规则时发生错误', e);
      return false;
    }
  }
  
  /// 检查防火墙规则是否存在
  static Future<bool> checkFirewallRules() async {
    if (!_isWindows) {
      return true;
    }
    
    try {
      final workingDir = _safeWorkingDirectory;
      final result = await Process.run(
        'netsh',
        ['advfirewall', 'firewall', 'show', 'rule', 'name=$_ruleName'],
        runInShell: true,
        workingDirectory: workingDir,
      );
      
      return result.exitCode == 0 && result.stdout.toString().contains(_ruleName);
    } catch (e) {
      await Logger.logError('检查防火墙规则时发生错误', e);
      return false;
    }
  }
  
  /// 删除防火墙规则
  static Future<bool> removeFirewallRules() async {
    if (!_isWindows) {
      return true;
    }
    
    try {
      await Logger.logInfo('开始删除Windows防火墙规则');
      
      final workingDir = _safeWorkingDirectory;
      final result = await _deleteExistingRule(workingDir);
      
      if (result) {
        await Logger.logInfo('Windows防火墙规则删除成功: $_ruleName');
      } else {
        await Logger.logWarning('删除防火墙规则时发生错误');
      }
      
      return result;
    } catch (e) {
      await Logger.logError('删除防火墙规则时发生错误', e);
      return false;
    }
  }
}
