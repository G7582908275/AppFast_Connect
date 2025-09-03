import 'dart:io';
import 'lib/services/windows_firewall_service.dart';
import 'lib/utils/logger.dart';

void main() async {
  // 初始化日志
  await Logger.initialize();
  
  print('=== 测试Windows防火墙修复 ===');
  
  // 检查当前工作目录
  final currentDir = Directory.current.path;
  print('当前工作目录: $currentDir');
  
  // 检查是否为UNC路径
  if (currentDir.startsWith('\\\\')) {
    print('警告: 当前工作目录是UNC路径，这可能导致问题');
  } else {
    print('当前工作目录不是UNC路径，应该正常工作');
  }
  
  // 检查系统信息
  print('\n系统信息:');
  print('操作系统: ${Platform.operatingSystem}');
  print('操作系统版本: ${Platform.operatingSystemVersion}');
  print('系统临时目录: ${Directory.systemTemp.path}');
  
  // 检查环境变量
  print('\n环境变量:');
  final tempEnv = Platform.environment['TEMP'];
  final tmpEnv = Platform.environment['TMP'];
  print('TEMP: $tempEnv');
  print('TMP: $tmpEnv');
  
  // 检查core.exe文件
  final corePath = '${Directory.systemTemp.path}/appfast_connect/core.exe';
  final coreFile = File(corePath);
  final coreExists = await coreFile.exists();
  print('\ncore.exe文件检查:');
  print('路径: $corePath');
  print('存在: $coreExists');
  if (coreExists) {
    final size = await coreFile.length();
    print('大小: $size bytes');
  }
  
  // 测试netsh命令
  print('\n测试netsh命令...');
  try {
    final result = await Process.run('netsh', ['advfirewall', 'show', 'allprofiles'], runInShell: true);
    print('netsh测试结果:');
    print('退出码: ${result.exitCode}');
    if (result.stdout.isNotEmpty) {
      print('输出: ${result.stdout.toString().substring(0, result.stdout.toString().length > 100 ? 100 : result.stdout.toString().length)}...');
    }
    if (result.stderr.isNotEmpty) {
      print('错误: ${result.stderr}');
    }
  } catch (e) {
    print('netsh命令测试失败: $e');
  }
  
  // 测试防火墙规则添加
  print('\n开始测试防火墙规则添加...');
  final result = await WindowsFirewallService.addFirewallRules();
  
  if (result) {
    print('✅ 防火墙规则添加成功');
  } else {
    print('❌ 防火墙规则添加失败');
  }
  
  // 检查防火墙规则是否存在
  print('\n检查防火墙规则是否存在...');
  final exists = await WindowsFirewallService.checkFirewallRules();
  
  if (exists) {
    print('✅ 防火墙规则存在');
  } else {
    print('❌ 防火墙规则不存在');
  }
  
  // 清理防火墙规则
  print('\n清理防火墙规则...');
  final cleaned = await WindowsFirewallService.removeFirewallRules();
  
  if (cleaned) {
    print('✅ 防火墙规则清理成功');
  } else {
    print('❌ 防火墙规则清理失败');
  }
  
  print('\n=== 测试完成 ===');
}
