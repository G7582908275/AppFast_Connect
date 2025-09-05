import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/platform_utils.dart';
import '../utils/logger.dart';
import 'flutter_vpn_service.dart';


class VPNService {
  static Process? _vpnProcess;
  static bool _isConnected = false;
  static const String _clashApiUrl = 'http://127.0.0.1:13129';
  static const String _clashSecret = 'JTxTN1IgXSGY3p5A';
  
  /// 初始化VPN服务
  static void initialize() {
    // 设置进程清理服务的断开连接回调
  }
  
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
      
      // 连接前先访问shutdown接口确保无残留
      await _callShutdownAPI();
      
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
        
        // 优化后的代码
        final executablePath = await PlatformUtils.getExecutablePath();

        // 检查文件是否存在
        final file = File(executablePath);
        if (!await file.exists()) {
          return {'success': false, 'error': '可执行文件不存在，请检查应用安装'};
        }

        // 根据平台确定工作目录
        final workingDir = PlatformUtils.isWindows 
            ? await PlatformUtils.getWorkingDirectory()
            : '/tmp/appfast_connect';

        // 构建命令参数（所有平台都相同）
        final arguments = [
          'run',
          '-c',
          '$subscriptionId',
          '-D',
          workingDir,
          '-H',
          '1'
        ];

        // 详细记录VPN调用信息
        await Logger.logInfo('=== VPN调用信息 (connectWithError) ===');
        await Logger.logInfo('平台: ${Platform.operatingSystem}');
        await Logger.logInfo('架构: ${PlatformUtils.architecture}');
        await Logger.logInfo('可执行文件路径: $executablePath');
        await Logger.logInfo('参数列表: ${arguments.join(' ')}');
        await Logger.logInfo('工作目录: $workingDir');
        await Logger.logInfo('完整命令: $executablePath ${arguments.join(' ')}');
        await Logger.logInfo('=== VPN调用信息结束 ===');
        

        
        // 执行命令
        if (PlatformUtils.isWindows) {
          // Windows: 直接启动，不使用shell，后台运行
          _vpnProcess = await Process.start(
            executablePath, 
            arguments,
            workingDirectory: workingDir,
            environment: PlatformUtils.getEnvironmentVariables(),
            runInShell: false
          );
        } else {
          _vpnProcess = await Process.start(
            executablePath, 
            arguments,
            workingDirectory: workingDir,
            environment: PlatformUtils.getEnvironmentVariables(),
            runInShell: true
          );
        }

        // 等待启动判定（API 可用 / 日志成功 / 进程异常退出）
        final result = await _awaitStartupOrFailure(
          _vpnProcess!,
          timeout: const Duration(seconds: 30),
        );
        if (!result['success']) {
          try { _vpnProcess?.kill(); } catch (_) {}
          _vpnProcess = null;
          _isConnected = false;
          return {'success': false, 'error': result['error'] ?? '网络服务启动失败，请检查网络连接或联系客服'};
        }

        _isConnected = true;
        return {'success': true, 'error': null};
      }
      return {'success': false, 'error': '不支持的操作系统'};
    } catch (e) {
      return {'success': false, 'error': '连接过程中发生错误: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> _awaitStartupOrFailure(Process p, {required Duration timeout}) async {
    final completer = Completer<Map<String, dynamic>>();
    Timer? timer;
    StreamSubscription<String>? outSub;
    StreamSubscription<String>? errSub;
    bool apiOk = false;

    Future<void> finish(bool ok, {String? error}) async {
      if (completer.isCompleted) return;
      completer.complete({'success': ok, 'error': error});
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
        } else if (code == 1) {
          await Logger.logError('服务码失效 (1): 订阅服务码无效或已过期');
        } else if (code > 0) {
          await Logger.logInfo('异常退出 ($code): 进程异常结束');
        } else {
          await Logger.logInfo('信号终止 ($code): 进程被信号终止');
        }

        // 此处休眠1秒，等待api服务启动
        await Future.delayed(const Duration(seconds: 2));
        
        if (!completer.isCompleted) {
          if (code == 0) {
            // 正常退出
            if (apiOk) {
              await Logger.logInfo('VPN进程正常退出，API可用，连接成功');
              await finish(true);
            } else {
              await Logger.logInfo('VPN进程正常退出，但API不可用，连接失败');
              await finish(false, error: '网络服务启动失败，请检查网络连接或联系客服');
            }
          } else if (code == 1) {
            // 服务码失效
            await Logger.logError('VPN进程因服务码失效退出（退出码1）');
            await finish(false, error: '服务码失效，请联系客服');
          } else if (code == -13) {
            // SIGPIPE退出，这是常见的情况
            await Logger.logWarning('VPN进程被SIGPIPE终止（退出码-13）');
            if (apiOk) {
              await Logger.logInfo('尽管进程被SIGPIPE终止，但API可用，认为连接成功');
              await finish(true);
            } else {
              await Logger.logInfo('进程被SIGPIPE终止且API不可用，认为连接失败');
              await finish(false, error: '网络服务启动失败，请检查网络连接或联系客服');
            }
          } else {
            // 其他异常退出
            await Logger.logError('VPN进程异常退出，退出码: $code');
            if (apiOk) {
              await Logger.logInfo('尽管进程异常退出，但API可用，认为连接成功');
              await finish(true);
            } else {
              await finish(false, error: '网络服务启动失败，请检查网络连接或联系客服');
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
          await finish(false, error: '网络服务启动超时，请检查网络连接或联系客服');
        }
      }
    });

    return completer.future;
  }
  
  static Future<bool> disconnect() async {
    try {
      // 访问shutdown接口来断开连接
      await _callShutdownAPI();
      
      // 清理进程引用
      if (_vpnProcess != null) {
        _vpnProcess = null;
      }
      
      // 清理 API 状态
      _isConnected = false;
      
      return true;
    } catch (e) {
      await Logger.logError('断开连接时发生错误', e);
      return false;
    }
  }
  
  /// 调用shutdown接口断开连接
  static Future<void> _callShutdownAPI() async {
    try {
      final uri = Uri.parse('http://127.0.0.1:13127/shutdown');
      await Logger.logInfo('正在访问shutdown接口: $uri');
      
      final response = await http.post(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        await Logger.logInfo('shutdown接口调用成功');
      } else {
        await Logger.logWarning('shutdown接口返回状态码: ${response.statusCode}');
      }
    } catch (e) {
      await Logger.logError('调用shutdown接口失败', e);
      // 即使shutdown接口调用失败，也不影响断开连接的流程
    }
  }
   
  static bool get isConnected {
    return _isConnected;
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

  // 只转换为Mb/s，不考虑其他单位
  String _formatBitsPerSecond(int bytesPerSec) {
    final double mbps = bytesPerSec * 8 / 1000000;
    return '${mbps.toStringAsFixed(mbps < 10 ? 2 : 1)} Mb/s';
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
