import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/platform_utils.dart';
import '../utils/permission_utils.dart';
import '../utils/logger.dart';
import 'flutter_vpn_service.dart';
import 'windows_firewall_service.dart';

class VPNService {
  static Process? _vpnProcess;
  static bool _isConnected = false;
  static const String _clashApiUrl = 'http://127.0.0.1:13129';
  static const String _clashSecret = 'JTxTN1IgXSGY3p5A';
  
  /// 获取订阅序号
  static Future<String?> _getSubscriptionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('subscription_id');
    } catch (e) {
      await Logger.logError('获取订阅序号失败', e);
      return null;
    }
  }
  
  /// 验证订阅序号
  static Future<bool> _validateSubscriptionId(String? subscriptionId) {
    return Future.value(subscriptionId != null && subscriptionId.trim().isNotEmpty);
  }
  
  /// 获取 Clash API 请求头
  static Map<String, String> get _clashHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_clashSecret',
  };
  
  /// 统一 GET 调用（带超时/日志）
  static Future<http.Response?> _get(String path, {Duration timeout = const Duration(seconds: 10)}) async {
    final uri = Uri.parse('$_clashApiUrl$path');
    try {
      final resp = await http.get(uri, headers: _clashHeaders).timeout(timeout);
      return resp;
    } catch (e) {
      return null;
    }
  }

  /// 检查 Clash API 状态
  static Future<bool> checkClashAPI() async {
    if (kIsWeb) {
      // Web平台返回模拟状态
      return false;
    }
    
    final response = await _get('/configs');
    if (response != null && response.statusCode == 200) {
      return true;
    }
    return false;
  }
  
  /// 获取 Clash 配置信息
  static Future<Map<String, dynamic>?> getClashConfig() async {
    final response = await _get('/configs');
    if (response != null && response.statusCode == 200) {
      return json.decode(response.body);
    }
    
    return null;
  }
  
  /// 获取 Clash 代理状态
  static Future<Map<String, dynamic>?> getClashProxies() async {
    final response = await _get('/proxies');
    if (response != null && response.statusCode == 200) {
      return json.decode(response.body);
    }
    
    return null;
  }
  
  /// 获取 Clash 连接状态
  static Future<Map<String, dynamic>?> getClashConnections() async {
    final response = await _get('/connections');
    if (response != null && response.statusCode == 200) {
      return json.decode(response.body);
    }
    
    return null;
  }

  /// 获取 Clash 流量（累计上/下行字节数）
  static Future<Map<String, int>?> getClashTraffic() async {
    final response = await _get('/traffic');
    if (response != null && response.statusCode == 200) {
      final dynamic body = json.decode(response.body);
      if (body is Map<String, dynamic>) {
        final dynamic upVal = body['up'] ?? body['upload'] ?? body['upBytes'];
        final dynamic downVal = body['down'] ?? body['download'] ?? body['downBytes'];
        if (upVal is int && downVal is int) {
          return {'up': upVal, 'down': downVal};
        }
        if (upVal is num && downVal is num) {
          return {'up': upVal.toInt(), 'down': downVal.toInt()};
        }
      }
    }
    return null;
  }

  /// 以流的方式订阅 Clash /traffic（长连接，SSE 或逐行 JSON）
  static Stream<Map<String, int>> streamClashTraffic() async* {
    final client = HttpClient()..idleTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse('$_clashApiUrl/traffic'));
      // 设置认证和 SSE 相关头
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_clashSecret');
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');

      final response = await request.close();
      if (response.statusCode != 200) {
        client.close(force: true);
        return;
      }

      // 将字节流解码为行
      final lines = response.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        String jsonPart = line.trim();
        if (jsonPart.startsWith('data:')) {
          jsonPart = jsonPart.substring(5).trim();
        }
        try {
          final dynamic obj = json.decode(jsonPart);
          if (obj is Map<String, dynamic>) {
            final upVal = obj['up'];
            final downVal = obj['down'];
            if (upVal is int && downVal is int) {
              yield {'up': upVal, 'down': downVal};
            } else if (upVal is num && downVal is num) {
              yield {'up': upVal.toInt(), 'down': downVal.toInt()};
            }
          }
        } catch (_) {
          // 忽略无法解析的行
        }
      }
    } catch (e) {
      // 连接失败或被对端正常关闭，静默结束
    } finally {
      try { client.close(force: true); } catch (_) {}
    }
  }
  
  static Future<Map<String, dynamic>> connectWithError() async {
    try {
      // 检查平台
      if (kIsWeb) {
        return {'success': false, 'error': 'Web平台不支持VPN连接'};
      }
      
      // 获取并验证订阅序号
      final subscriptionId = await _getSubscriptionId();
      final isValidSubscription = await _validateSubscriptionId(subscriptionId);
      
      if (!isValidSubscription) {
        return {'success': false, 'error': '请先填写订阅序号'};
      }
      
      // Android平台使用Flutter VPN服务
      if (Platform.isAndroid) {
        await Logger.logInfo('Android平台，使用Flutter VPN服务');
        
        try {
          // 调用Flutter VPN服务
          final success = await FlutterVPNService.startVPN(
            subscriptionId: subscriptionId!,
            serverAddress: 'your-server.com', // 从配置获取
            serverPort: 443,
            encryptionMethod: 'aes-256-gcm',
            password: 'your-password', // 从配置获取
          );
          
          if (success) {
            await Logger.logInfo('Android VPN服务启动成功');
            _isConnected = true;
            return {'success': true, 'error': null};
          } else {
            await Logger.logError('Android VPN服务启动失败');
            return {'success': false, 'error': 'Android VPN服务启动失败'};
          }
        } catch (e) {
          await Logger.logError('Android VPN服务启动失败', e);
          return {'success': false, 'error': 'Android VPN服务启动失败: ${e.toString()}'};
        }
      }
      
      // 桌面平台使用原有逻辑
      if (PlatformUtils.isMacOS || PlatformUtils.isWindows || PlatformUtils.isLinux) {
        // 获取并验证订阅序号
        final subscriptionId = await _getSubscriptionId();
        final isValidSubscription = await _validateSubscriptionId(subscriptionId);
        
        if (!isValidSubscription) {
          return {'success': false, 'error': '请先填写订阅序号'};
        }
        
        // 清理并重新获取可执行文件路径
        await PlatformUtils.cleanupExecutableFiles();
        
        // 检查并请求管理员权限（macOS需要sudo，Windows需要管理员权限）
        if (PlatformUtils.isMacOS) {
          final hasSudo = await PermissionUtils.hasSudoPrivileges();
          if (!hasSudo) {
            final sudoGranted = await PermissionUtils.requestSudoPrivileges();
            if (!sudoGranted) {
              return {'success': false, 'error': '管理员密码验证失败，请检查密码是否正确'};
            }
          }
        } else if (PlatformUtils.isWindows) {
          final hasAdmin = await PermissionUtils.hasSudoPrivileges();
          if (!hasAdmin) {
            final adminGranted = await PermissionUtils.requestSudoPrivileges();
            if (!adminGranted) {
              return {'success': false, 'error': '需要管理员权限才能连接VPN，请以管理员身份运行应用'};
            }
          }
        }
        
        final executablePath = await PlatformUtils.getExecutablePath();
        
        // 检查文件是否存在
        final file = File(executablePath);
        if (!await file.exists()) {
          return {'success': false, 'error': 'VPN 可执行文件不存在，请检查应用安装'};
        }
        
        // 根据平台构建不同的命令
        String command;
        List<String> arguments;
        String workingDir;
        
        if (PlatformUtils.isMacOS) {
          // macOS: 使用 sudo
          command = 'sudo';
          arguments = [
            executablePath,
            'run',
            '-c',
            'https://sdn-manager.ipam.zone/v2/$subscriptionId?download=mac-safe',
            '-D',
            '/tmp/appfast_connect'
          ];
          workingDir = '/tmp/appfast_connect';
        } else if (PlatformUtils.isWindows) {
          // Windows: 直接执行，可能需要管理员权限
          command = executablePath;
          arguments = [
            'run',
            '-c',
            'https://sdn-manager.ipam.zone/v2/$subscriptionId?download=win',
            '-D',
            await PlatformUtils.getWorkingDirectory()
          ];
          workingDir = await PlatformUtils.getWorkingDirectory();
        } else if (PlatformUtils.isLinux) {
          // Linux: 直接执行，可能需要root权限
          command = executablePath;
          arguments = [
            'run',
            '-c',
            'https://sdn-manager.ipam.zone/v2/$subscriptionId?download=linux',
            '-D',
            '/tmp/appfast_connect'
          ];
          workingDir = '/tmp/appfast_connect';
        } else {
          return {'success': false, 'error': '不支持的操作系统'};
        }
        
        // 详细记录VPN调用信息
        await Logger.logInfo('=== VPN调用信息 (connectWithError) ===');
        await Logger.logInfo('平台: ${Platform.operatingSystem}');
        await Logger.logInfo('架构: ${PlatformUtils.architecture}');
        await Logger.logInfo('命令: $command');
        await Logger.logInfo('可执行文件路径: $executablePath');
        await Logger.logInfo('参数列表: ${arguments.join(' ')}');
        await Logger.logInfo('工作目录: $workingDir');
        await Logger.logInfo('完整命令: $command ${arguments.join(' ')}');
        await Logger.logInfo('=== VPN调用信息结束 ===');
        
        // 创建VPN工作目录
        final vpnWorkDir = Directory(workingDir);
        if (!await vpnWorkDir.exists()) {
          await vpnWorkDir.create(recursive: true);
        }
        
        // 执行命令
        _vpnProcess = await Process.start(
          command, 
          arguments,
          workingDirectory: workingDir,
          environment: PlatformUtils.getEnvironmentVariables(),
        );

        // 等待启动判定（API 可用 / 日志成功 / 进程异常退出）
        final started = await _awaitStartupOrFailure(
          _vpnProcess!,
          timeout: const Duration(seconds: 30),
        );
        if (!started) {
          try { _vpnProcess?.kill(); } catch (_) {}
          _vpnProcess = null;
          _isConnected = false;
          return {'success': false, 'error': 'VPN 服务启动失败，请检查网络连接或联系客服'};
        }

        _isConnected = true;
        return {'success': true, 'error': null};
      }
      return {'success': false, 'error': '不支持的操作系统'};
    } catch (e) {
      return {'success': false, 'error': '连接过程中发生错误: ${e.toString()}'};
    }
  }

  static Future<bool> connect() async {
    try {
      // 检查平台
      if (kIsWeb) {
        await Logger.logInfo('Web平台不支持VPN连接');
        return false;
      }
      
      // Android平台使用Flutter VPN服务
      if (Platform.isAndroid) {
        await Logger.logInfo('Android平台，使用Flutter VPN服务');
        
        // 获取并验证订阅序号
        final subscriptionId = await _getSubscriptionId();
        final isValidSubscription = await _validateSubscriptionId(subscriptionId);
        
        if (!isValidSubscription) {
          await Logger.logError('订阅序号未填写或无效');
          return false;
        }
        
        try {
          // 调用Flutter VPN服务
          final success = await FlutterVPNService.startVPN(
            subscriptionId: subscriptionId!,
            serverAddress: 'your-server.com', // 从配置获取
            serverPort: 443,
            encryptionMethod: 'aes-256-gcm',
            password: 'your-password', // 从配置获取
          );
          
          if (success) {
            await Logger.logInfo('Android VPN服务启动成功');
            _isConnected = true;
            return true;
          } else {
            await Logger.logError('Android VPN服务启动失败');
            return false;
          }
        } catch (e) {
          await Logger.logError('Android VPN服务启动失败', e);
          return false;
        }
      }
      
      // 桌面平台使用原有逻辑
      if (PlatformUtils.isMacOS || PlatformUtils.isWindows || PlatformUtils.isLinux) {
        await Logger.logInfo('开始VPN连接流程...');
        
        // 获取并验证订阅序号
        final subscriptionId = await _getSubscriptionId();
        final isValidSubscription = await _validateSubscriptionId(subscriptionId);
        
        if (!isValidSubscription) {
          await Logger.logError('订阅序号未填写或无效');
          return false;
        }
        
        // 首先验证可执行文件
        final isValidFile = await PlatformUtils.validateExecutableFile();
        if (!isValidFile) {
          await Logger.logError('可执行文件验证失败');
          return false;
        }
        
        // 清理并重新获取可执行文件路径
        await PlatformUtils.cleanupExecutableFiles();
        
        // 检查并请求管理员权限（macOS需要sudo，Windows需要管理员权限）
        if (PlatformUtils.isMacOS) {
          final hasSudo = await PermissionUtils.hasSudoPrivileges();
          if (!hasSudo) {
            await Logger.logInfo('请求sudo权限...');
            final sudoGranted = await PermissionUtils.requestSudoPrivileges();
            if (!sudoGranted) {
              await Logger.logError('sudo权限获取失败');
              return false;
            }
          }
        } else if (PlatformUtils.isWindows) {
          final hasAdmin = await PermissionUtils.hasSudoPrivileges();
          if (!hasAdmin) {
            await Logger.logInfo('请求管理员权限...');
            final adminGranted = await PermissionUtils.requestSudoPrivileges();
            if (!adminGranted) {
              await Logger.logError('管理员权限获取失败');
              return false;
            }
          }
          
          // 检查并添加Windows防火墙规则
          await Logger.logInfo('检查Windows防火墙规则...');
          final hasFirewallRules = await WindowsFirewallService.checkFirewallRules();
          if (!hasFirewallRules) {
            await Logger.logInfo('防火墙规则不存在，正在添加...');
            final firewallResult = await WindowsFirewallService.addFirewallRules();
            if (!firewallResult) {
              await Logger.logWarning('防火墙规则添加失败，但继续VPN连接');
            }
          } else {
            await Logger.logInfo('Windows防火墙规则已存在');
          }
        }
        
        final executablePath = await PlatformUtils.getExecutablePath();
        await Logger.logInfo('使用可执行文件: $executablePath');
        
        // 检查文件是否存在
        final file = File(executablePath);
        if (!await file.exists()) {
          await Logger.logError('可执行文件不存在: $executablePath');
          return false;
        }
        
        // 根据平台构建不同的命令
        String command;
        List<String> arguments;
        String workingDir;
        
        if (PlatformUtils.isMacOS) {
          // macOS: 使用 sudo
          command = 'sudo';
          arguments = [
            executablePath,
            'run',
            '-c',
            'https://sdn-manager.ipam.zone/v2/$subscriptionId?download=mac-safe',
            '-D',
            '/tmp/appfast_connect'
          ];
          workingDir = '/tmp/appfast_connect';
        } else if (PlatformUtils.isWindows) {
          // Windows: 直接执行，可能需要管理员权限
          command = executablePath;
          arguments = [
            'run',
            '-c',
            'https://sdn-manager.ipam.zone/v2/$subscriptionId?download=windows-safe',
            '-D',
            await PlatformUtils.getWorkingDirectory()
          ];
          workingDir = await PlatformUtils.getWorkingDirectory();
        } else if (PlatformUtils.isLinux) {
          // Linux: 直接执行，可能需要root权限
          command = executablePath;
          arguments = [
            'run',
            '-c',
            'https://sdn-manager.ipam.zone/v2/$subscriptionId?download=openwrt-safe',
            '-D',
            '/tmp/appfast_connect'
          ];
          workingDir = '/tmp/appfast_connect';
        } else {
          await Logger.logError('不支持的操作系统');
          return false;
        }
        
        // 详细记录VPN调用信息
        await Logger.logInfo('=== VPN调用信息 ===');
        await Logger.logInfo('平台: ${Platform.operatingSystem}');
        await Logger.logInfo('架构: ${PlatformUtils.architecture}');
        await Logger.logInfo('命令: $command');
        await Logger.logInfo('可执行文件路径: $executablePath');
        await Logger.logInfo('参数列表: ${arguments.join(' ')}');
        await Logger.logInfo('工作目录: $workingDir');
        await Logger.logInfo('完整命令: $command ${arguments.join(' ')}');
        
        // 记录当前工作目录信息
        final currentDir = Directory.current;
        await Logger.logInfo('当前工作目录: ${currentDir.path}');
        await Logger.logInfo('应用可执行路径: ${Platform.resolvedExecutable}');
        
        // 创建VPN工作目录
        final vpnWorkDir = Directory(workingDir);
        if (!await vpnWorkDir.exists()) {
          await vpnWorkDir.create(recursive: true);
        }
        await Logger.logInfo('VPN工作目录: ${vpnWorkDir.path}');
        
        // 记录环境变量
        final envVars = PlatformUtils.getEnvironmentVariables();
        await Logger.logInfo('环境变量: $envVars');
        await Logger.logInfo('=== VPN调用信息结束 ===');
        
        // 执行命令，设置工作目录
        _vpnProcess = await Process.start(
          command, 
          arguments,
          workingDirectory: workingDir,
          environment: envVars,
        );

        // 等待启动判定（API 可用 / 日志成功 / 进程异常退出）
        final started = await _awaitStartupOrFailure(
          _vpnProcess!,
          timeout: const Duration(seconds: 30),
        );
        if (!started) {
          await Logger.logError('VPN启动失败');
          try { _vpnProcess?.kill(); } catch (_) {}
          _vpnProcess = null;
          _isConnected = false;
          return false;
        }

        await Logger.logInfo('VPN连接成功');
        _isConnected = true;
        return true;
      }
      return false;
    } catch (e) {
      await Logger.logError('VPN连接过程中发生错误', e);
      return false;
    }
  }

  static Future<bool> _awaitStartupOrFailure(Process p, {required Duration timeout}) async {
    final completer = Completer<bool>();
    Timer? timer;
    StreamSubscription<String>? outSub;
    StreamSubscription<String>? errSub;
    bool apiOk = false;

    Future<void> finish(bool ok) async {
      if (completer.isCompleted) return;
      completer.complete(ok);
      await outSub?.cancel();
      await errSub?.cancel();
      timer?.cancel();
    }

    // 监听标准输出
    outSub = p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) async {
      await Logger.logInfo('VPN输出: $line');
    });

    // 监听标准错误
    errSub = p.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) async {
      // 检查是否是真正的错误信息
      if (line.contains('ERROR') || line.contains('FATAL') || line.contains('panic')) {
        await Logger.logError('VPN错误: $line');
      } else if (line.contains('INFO') || line.contains('WARN')) {
        await Logger.logInfo('VPN日志: $line');
      } else {
        // 其他stderr输出，可能是正常的日志
        await Logger.logInfo('VPN输出: $line');
      }
    });

    // 并行周期性检查 Clash API（每 2 秒一次）
    Timer.periodic(const Duration(seconds: 2), (t) async {
      if (completer.isCompleted) { t.cancel(); return; }
      
      try {
        final ok = await checkClashAPI();
        if (ok) {
          apiOk = true;
          t.cancel();
          await Logger.logInfo('Clash API检查成功，VPN连接成功');
          await finish(true);
        }
      } catch (e) {
        await Logger.logError('API检查异常', e);
      }
    });

    // 监控进程退出
    (() async {
      try {
        final code = await p.exitCode;
        await Logger.logInfo('VPN进程退出，退出码: $code');
        
        // 分析退出码
        if (code == -13) {
          await Logger.logInfo('SIGPIPE (13): 进程被管道破裂信号终止，这通常是正常的');
        } else if (code == 0) {
          await Logger.logInfo('正常退出 (0): 进程正常结束');
        } else if (code > 0) {
          await Logger.logInfo('异常退出 ($code): 进程异常结束');
        } else {
          await Logger.logInfo('信号终止 ($code): 进程被信号终止');
        }
        
        if (!completer.isCompleted) {
          if (code == 0) {
            // 正常退出
            if (apiOk) {
              await Logger.logInfo('VPN进程正常退出，API可用，连接成功');
              await finish(true);
            } else {
              await Logger.logInfo('VPN进程正常退出，但API不可用，连接失败');
              await finish(false);
            }
          } else if (code == -13) {
            // SIGPIPE退出，这是常见的情况
            await Logger.logWarning('VPN进程被SIGPIPE终止（退出码-13）');
            if (apiOk) {
              await Logger.logInfo('尽管进程被SIGPIPE终止，但API可用，认为连接成功');
              await finish(true);
            } else {
              await Logger.logInfo('进程被SIGPIPE终止且API不可用，认为连接失败');
              await finish(false);
            }
          } else {
            // 其他异常退出
            await Logger.logError('VPN进程异常退出，退出码: $code');
            if (apiOk) {
              await Logger.logInfo('尽管进程异常退出，但API可用，认为连接成功');
              await finish(true);
            } else {
              await finish(false);
            }
          }
        }
      } catch (e) {
        await Logger.logError('监控VPN进程时发生错误', e);
      }
    })();

    // 超时处理
    timer = Timer(timeout, () async {
      if (!completer.isCompleted) {
        await Logger.logWarning('VPN启动超时');
        if (apiOk) {
          await Logger.logInfo('超时但API可用，认为连接成功');
          await finish(true);
        } else {
          await finish(false);
        }
      }
    });

    return completer.future;
  }
  
  static Future<bool> disconnect() async {
    try {
      if (_vpnProcess != null) {
        // 安全地终止 VPN 进程
        try {
          // 优雅终止（不依赖 exitCode null 检查）
          _vpnProcess!.kill();
          try {
            await _vpnProcess!.exitCode.timeout(const Duration(seconds: 5));
          } catch (e) {
            _vpnProcess!.kill(ProcessSignal.sigkill);
          }
        } catch (e) {
          // Error managing process
        }
        
        _vpnProcess = null;
      }
      
      // 清理 API 状态
      _isConnected = false;
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static String getCurrentArchitecture() {
    return PlatformUtils.architecture;
  }
  
  static String getLibraryFileName() {
    return PlatformUtils.libraryFileName;
  }
  
  /// 获取详细的 VPN 状态信息
  static Future<Map<String, dynamic>> getVPNStatus() async {
    final status = <String, dynamic>{
      'connected': _isConnected,
      'process_running': _vpnProcess != null,
      'clash_api_url': _clashApiUrl,
    };
    
    // 获取 Clash 配置信息
    final clashConfig = await getClashConfig();
    if (clashConfig != null) {
      status['clash_config'] = clashConfig;
    }
    
    // 获取 Clash 代理状态
    final clashProxies = await getClashProxies();
    if (clashProxies != null) {
      status['clash_proxies'] = clashProxies;
    }
    
    // 获取 Clash 连接状态
    final clashConnections = await getClashConnections();
    if (clashConnections != null) {
      status['clash_connections'] = clashConnections;
    }
        
    return status;
  }
  
  static bool get isConnected {
    return _isConnected;
  }
  
  /// 异步检查连接状态（使用 Clash API）
  static Future<bool> checkConnectionStatus() async {
    // 首先检查 Clash API
    final apiAvailable = await checkClashAPI();
    if (apiAvailable) {
      _isConnected = true;
      return true;
    }
    
    // 如果 API 不可用，检查 VPN 进程是否在运行（粗略）
    if (_vpnProcess != null) {
      _isConnected = true;
      return true;
    }
    
    // 如果进程已经退出，检查是否有 VPN 接口在运行
    if (Platform.isMacOS) {
      try {
        final result = Process.runSync('ifconfig', []);
        final output = (result.stdout ?? '').toString();
        if (RegExp(r'\butun\d+').hasMatch(output)) {
          _isConnected = true;
          return true;
        }
      } catch (e) {
        // 忽略错误
      }
    } else if (Platform.isWindows) {
      try {
        // Windows: 检查网络适配器
        final result = Process.runSync('netsh', ['interface', 'show', 'interface']);
        final output = (result.stdout ?? '').toString();
        if (RegExp(r'\bTAP-Windows Adapter\b', caseSensitive: false).hasMatch(output) ||
            RegExp(r'\bVPN\b', caseSensitive: false).hasMatch(output)) {
          _isConnected = true;
          return true;
        }
      } catch (e) {
        // 忽略错误
      }
    } else if (Platform.isLinux) {
      try {
        // Linux: 检查网络接口
        final result = Process.runSync('ip', ['link', 'show']);
        final output = (result.stdout ?? '').toString();
        if (RegExp(r'\btun\d+\b').hasMatch(output) || 
            RegExp(r'\btap\d+\b').hasMatch(output)) {
          _isConnected = true;
          return true;
        }
      } catch (e) {
        // 忽略错误
      }
    }
    
    _isConnected = false;
    return false;
  }
}

/// VPN 连接管理器
class ConnectionManager {
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectionTime;
  DateTime? _connectionStartTime;
  String? _upText;
  String? _downText;
  String? _errorMessage;
  
  StreamSubscription<Map<String, int>>? _trafficSub;
  Timer? _connectionTimer;
  Timer? _debounceTimer;
  
  // 回调函数
  final Function(bool) onConnectionStateChanged;
  final Function(bool) onConnectingStateChanged;
  final Function(String?) onConnectionTimeChanged;
  final Function(String?) onUploadSpeedChanged;
  final Function(String?) onDownloadSpeedChanged;
  final Function(String?) onErrorChanged;
  final VoidCallback onDispose;

  ConnectionManager({
    required this.onConnectionStateChanged,
    required this.onConnectingStateChanged,
    required this.onConnectionTimeChanged,
    required this.onUploadSpeedChanged,
    required this.onDownloadSpeedChanged,
    required this.onErrorChanged,
    required this.onDispose,
  });

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectionTime => _connectionTime;
  String? get upText => _upText;
  String? get downText => _downText;
  String? get errorMessage => _errorMessage;

  Future<void> connect() async {
    _setConnecting(true);
    _setError(null);

    try {
      if (kIsWeb) {
        // Web平台模拟连接
        await Future.delayed(const Duration(seconds: 2));
        _setConnected(true);
        _setConnecting(false);
        _connectionStartTime = DateTime.now();
        _connectionTime = '00:00:00';
        _upText = '--';
        _downText = '--';
        
        onConnectionTimeChanged(_connectionTime);
        onUploadSpeedChanged(_upText);
        onDownloadSpeedChanged(_downText);
        
        _startConnectionTimer();
        _startTrafficStreaming();
      } else {
        final result = await VPNService.connectWithError();
        
        if (result['success'] == true) {
          _setConnected(true);
          _setConnecting(false);
          _connectionStartTime = DateTime.now();
          _connectionTime = '00:00:00';
          _upText = '--';
          _downText = '--';
          
          onConnectionTimeChanged(_connectionTime);
          onUploadSpeedChanged(_upText);
          onDownloadSpeedChanged(_downText);
          
          _startConnectionTimer();
          _startTrafficStreaming();
        } else {
          _setConnecting(false);
          _setError(result['error'] ?? '连接失败，请检查网络设置或联系客服');
        }
      }
    } catch (e) {
      _setConnecting(false);
      _setError('连接过程中发生错误: ${e.toString()}');
    }
  }

  Future<void> disconnect() async {
    try {
      _stopConnectionTimer();
      _stopTrafficStreaming();

      if (kIsWeb) {
        // Web平台模拟断开连接
        await Future.delayed(const Duration(seconds: 1));
        _setConnected(false);
        _setConnecting(false);
        _setError(null);
        _connectionTime = null;
        _connectionStartTime = null;
        _upText = null;
        _downText = null;
        
        onConnectionTimeChanged(_connectionTime);
        onUploadSpeedChanged(_upText);
        onDownloadSpeedChanged(_downText);
      } else {
        final success = await VPNService.disconnect();
        
        if (success) {
          _setConnected(false);
          _setConnecting(false);
          _setError(null);
          _connectionTime = null;
          _connectionStartTime = null;
          _upText = null;
          _downText = null;
          
          onConnectionTimeChanged(_connectionTime);
          onUploadSpeedChanged(_upText);
          onDownloadSpeedChanged(_downText);
        }
      }
    } catch (e) {
      // Disconnection error
    }
  }

  void _startConnectionTimer() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isConnected && _connectionStartTime != null) {
        final now = DateTime.now();
        final duration = now.difference(_connectionStartTime!);
        _connectionTime = _formatDuration(duration);
        onConnectionTimeChanged(_connectionTime);
      } else if (!_isConnected) {
        _connectionTime = null;
        onConnectionTimeChanged(_connectionTime);
        timer.cancel();
      }
    });
  }

  void _stopConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }

  void _startTrafficStreaming() {
    _trafficSub?.cancel();
    
    if (kIsWeb) {
      // Web平台模拟流量数据
      _trafficSub = Stream.periodic(const Duration(seconds: 1), (i) {
        final random = (i * 12345) % 1000000; // 简单的伪随机数
        return {
          'up': random,
          'down': random * 2,
        };
      }).listen((event) {
        final currentUp = (event['up'] ?? 0).toInt();
        final currentDown = (event['down'] ?? 0).toInt();

        // 使用防抖机制，避免频繁更新UI
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          _upText = _formatBitsPerSecond(currentUp);
          _downText = _formatBitsPerSecond(currentDown);
          onUploadSpeedChanged(_upText);
          onDownloadSpeedChanged(_downText);
        });
      });
    } else {
      // 非Web平台使用真实的VPN服务
      _trafficSub = VPNService.streamClashTraffic().listen((event) {
        final currentUp = (event['up'] ?? 0).toInt();
        final currentDown = (event['down'] ?? 0).toInt();

        // 使用防抖机制，避免频繁更新UI
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          _upText = _formatBitsPerSecond(currentUp);
          _downText = _formatBitsPerSecond(currentDown);
          onUploadSpeedChanged(_upText);
          onDownloadSpeedChanged(_downText);
        });
      });
    }
  }

  void _stopTrafficStreaming() {
    _trafficSub?.cancel();
    _trafficSub = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _setConnected(bool connected) {
    _isConnected = connected;
    onConnectionStateChanged(connected);
  }

  void _setConnecting(bool connecting) {
    _isConnecting = connecting;
    onConnectingStateChanged(connecting);
  }

  void _setError(String? error) {
    _errorMessage = error;
    onErrorChanged(error);
  }

  String _formatBitsPerSecond(int bytesPerSec) {
    final int bitsPerSec = bytesPerSec * 8;
    const units = ['b/s', 'Kb/s', 'Mb/s', 'Gb/s'];
    double value = bitsPerSec.toDouble();
    int unitIndex = 0;
    while (value >= 1000 && unitIndex < units.length - 1) {
      value /= 1000;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value < 10 ? 2 : 1)} ${units[unitIndex]}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void dispose() {
    _stopConnectionTimer();
    _stopTrafficStreaming();
    onDispose();
  }
}
