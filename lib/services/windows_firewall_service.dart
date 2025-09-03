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
  
  /// 添加防火墙规则
  static Future<bool> addFirewallRules() async {
    if (!_isWindows) {
      await Logger.logInfo('非Windows平台，跳过防火墙规则添加');
      return true;
    }
    
    try {
      await Logger.logInfo('开始添加Windows防火墙规则');
      
      // 删除旧规则（如果存在）
      await _deleteExistingRule();
      
      // 添加入站规则
      final inboundResult = await _addRule('in');
      if (!inboundResult) {
        await Logger.logError('添加入站防火墙规则失败');
        return false;
      }
      
      // 添加出站规则
      final outboundResult = await _addRule('out');
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
  
  /// 删除现有的防火墙规则
  static Future<bool> _deleteExistingRule() async {
    try {
      final result = await Process.run(
        'netsh',
        ['advfirewall', 'firewall', 'delete', 'rule', 'name=$_ruleName'],
        runInShell: true,
      );
      
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
  static Future<bool> _addRule(String direction) async {
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
      
      final result = await Process.run(
        'netsh',
        args,
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        await Logger.logInfo('成功添加${direction == 'in' ? '入站' : '出站'}防火墙规则');
        return true;
      } else {
        await Logger.logError('添加${direction == 'in' ? '入站' : '出站'}防火墙规则失败，退出码: ${result.exitCode}');
        await Logger.logError('命令输出: ${result.stderr}');
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
      final result = await Process.run(
        'netsh',
        ['advfirewall', 'firewall', 'show', 'rule', 'name=$_ruleName'],
        runInShell: true,
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
      
      final result = await _deleteExistingRule();
      
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
