import 'dart:io';
import 'dart:async';
import 'dart:convert';
// import 'dart:ffi' as ffi; // unused
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/platform_utils.dart';
import '../utils/permission_utils.dart';

class VPNService {
  static Process? _vpnProcess;
  static bool _isConnected = false;
  static const String _clashApiUrl = 'http://127.0.0.1:13129';
  static const String _clashSecret = 'JTxTN1IgXSGY3p5A';
  
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
  
  static Future<bool> connect() async {
    try {
      if (PlatformUtils.isMacOS) {
        // 检查并请求 sudo 权限
        final hasSudo = await PermissionUtils.hasSudoPrivileges();
        if (!hasSudo) {
          final sudoGranted = await PermissionUtils.requestSudoPrivileges();
          if (!sudoGranted) {
            return false;
          }
        }
        
        final executablePath = await PlatformUtils.getExecutablePath();
        
        // 检查文件是否存在
        final file = File(executablePath);
        if (!await file.exists()) {
          return false;
        }
        
        // 构建命令 - 使用 sudo 执行可执行文件
        final command = 'sudo';
        final arguments = [
          executablePath,
          'run',
          '-c',
          'https://sdn-manager.ipam.zone/v2/fldha0sis00nmeoz?download=mac'
        ];
        
        // 执行命令
        _vpnProcess = await Process.start(command, arguments);

        // 等待启动判定（API 可用 / 日志成功 / 进程异常退出）
        final started = await _awaitStartupOrFailure(
          _vpnProcess!,
          timeout: const Duration(seconds: 30),
        );
        if (!started) {
          try { _vpnProcess?.kill(); } catch (_) {}
          _vpnProcess = null;
          _isConnected = false;
          return false;
        }

        _isConnected = true;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _awaitStartupOrFailure(Process p, {required Duration timeout}) async {
    final completer = Completer<bool>();
    Timer? timer;
    StreamSubscription<String>? outSub;
    bool apiOk = false;

    Future<void> finish(bool ok) async {
      if (completer.isCompleted) return;
      completer.complete(ok);
      await outSub?.cancel();
      timer?.cancel();
    }

    // 监听日志仅用于打印，不参与判定
    outSub = p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      // VPN output logging removed
    });

    // 并行周期性检查 Clash API（每 2 秒一次）
    Timer.periodic(const Duration(seconds: 2), (t) async {
      if (completer.isCompleted) { t.cancel(); return; }
      final ok = await checkClashAPI();
      if (ok) {
        apiOk = true;
        t.cancel();
        await finish(true);
      }
    });

    // 监控进程快速退出（非 0 则失败）
    (() async {
      try {
        final code = await p.exitCode;
        if (!completer.isCompleted) {
          if (code == 0 && apiOk) {
            await finish(true);
          } else {
            await finish(false);
          }
        }
      } catch (_) {}
    })();

    // 超时处理
    timer = Timer(timeout, () async {
      if (!completer.isCompleted) {
        await finish(false);
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
    
    // 如果进程已经退出，检查是否有 VPN 接口在运行（不硬编码 utun4）
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
  
  StreamSubscription<Map<String, int>>? _trafficSub;
  Timer? _connectionTimer;
  Timer? _debounceTimer;
  
  // 回调函数
  final Function(bool) onConnectionStateChanged;
  final Function(bool) onConnectingStateChanged;
  final Function(String?) onConnectionTimeChanged;
  final Function(String?) onUploadSpeedChanged;
  final Function(String?) onDownloadSpeedChanged;
  final VoidCallback onDispose;

  ConnectionManager({
    required this.onConnectionStateChanged,
    required this.onConnectingStateChanged,
    required this.onConnectionTimeChanged,
    required this.onUploadSpeedChanged,
    required this.onDownloadSpeedChanged,
    required this.onDispose,
  });

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectionTime => _connectionTime;
  String? get upText => _upText;
  String? get downText => _downText;

  Future<void> connect() async {
    _setConnecting(true);

    try {
      final success = await VPNService.connect();
      
      if (success) {
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
      }
    } catch (e) {
      _setConnecting(false);
    }
  }

  Future<void> disconnect() async {
    try {
      _stopConnectionTimer();
      _stopTrafficStreaming();

      final success = await VPNService.disconnect();
      
      if (success) {
        _setConnected(false);
        _setConnecting(false);
        _connectionTime = null;
        _connectionStartTime = null;
        _upText = null;
        _downText = null;
        
        onConnectionTimeChanged(_connectionTime);
        onUploadSpeedChanged(_upText);
        onDownloadSpeedChanged(_downText);
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
