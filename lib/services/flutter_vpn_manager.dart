import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_vpn_service.dart';
import '../utils/logger.dart';

/// Flutter VPN连接管理器
class FlutterVPNManager {
  static bool _isConnected = false;
  static bool _isConnecting = false;
  static String? _connectionTime;
  static DateTime? _connectionStartTime;
  static String? _upText;
  static String? _downText;
  static String? _errorMessage;
  
  static StreamSubscription<Map<String, dynamic>>? _vpnStatusSub;
  static Timer? _connectionTimer;
  static Timer? _statsTimer;
  
  // 回调函数
  static Function(bool)? onConnectionStateChanged;
  static Function(bool)? onConnectingStateChanged;
  static Function(String?)? onConnectionTimeChanged;
  static Function(String?)? onUploadSpeedChanged;
  static Function(String?)? onDownloadSpeedChanged;
  static Function(String?)? onErrorChanged;
  
  /// 初始化VPN管理器
  static Future<void> initialize({
    Function(bool)? onConnectionStateChanged,
    Function(bool)? onConnectingStateChanged,
    Function(String?)? onConnectionTimeChanged,
    Function(String?)? onUploadSpeedChanged,
    Function(String?)? onDownloadSpeedChanged,
    Function(String?)? onErrorChanged,
  }) async {
    FlutterVPNManager.onConnectionStateChanged = onConnectionStateChanged;
    FlutterVPNManager.onConnectingStateChanged = onConnectingStateChanged;
    FlutterVPNManager.onConnectionTimeChanged = onConnectionTimeChanged;
    FlutterVPNManager.onUploadSpeedChanged = onUploadSpeedChanged;
    FlutterVPNManager.onDownloadSpeedChanged = onDownloadSpeedChanged;
    FlutterVPNManager.onErrorChanged = onErrorChanged;
    
    // 监听VPN状态变化
    _vpnStatusSub = FlutterVPNService.vpnStatusStream.listen((status) {
      final isConnected = status['isConnected'] ?? false;
      if (isConnected != _isConnected) {
        _setConnected(isConnected);
      }
    });
    
    await Logger.logInfo('Flutter VPN管理器初始化完成');
  }
  
  /// 连接VPN
  static Future<void> connect() async {
    if (_isConnecting) return;
    
    _setConnecting(true);
    _setError(null);
    
    try {
      // 检查VPN权限
      final hasPermission = await FlutterVPNService.checkVPNPermission();
      if (!hasPermission) {
        final granted = await FlutterVPNService.requestVPNPermission();
        if (!granted) {
          _setConnecting(false);
          _setError('VPN权限被拒绝');
          return;
        }
      }
      
      // 获取订阅信息
      final prefs = await SharedPreferences.getInstance();
      final subscriptionId = prefs.getString('subscription_id');
      
      if (subscriptionId == null || subscriptionId.isEmpty) {
        _setConnecting(false);
        _setError('请先填写订阅序号');
        return;
      }
      
      // 启动VPN服务
      final success = await FlutterVPNService.startVPN(
        subscriptionId: subscriptionId,
        serverAddress: 'your-server.com', // 从配置获取
        serverPort: 443,
        encryptionMethod: 'aes-256-gcm',
        password: 'your-password', // 从配置获取
      );
      
      if (success) {
        _setConnected(true);
        _setConnecting(false);
        _connectionStartTime = DateTime.now();
        _connectionTime = '00:00:00';
        _upText = '--';
        _downText = '--';
        
        onConnectionTimeChanged?.call(_connectionTime);
        onUploadSpeedChanged?.call(_upText);
        onDownloadSpeedChanged?.call(_downText);
        
        _startConnectionTimer();
        _startStatsTimer();
        
        await Logger.logInfo('Flutter VPN连接成功');
      } else {
        _setConnecting(false);
        _setError('VPN连接失败');
      }
      
    } catch (e) {
      _setConnecting(false);
      _setError('连接过程中发生错误: ${e.toString()}');
      await Logger.logError('Flutter VPN连接异常', e);
    }
  }
  
  /// 断开VPN连接
  static Future<void> disconnect() async {
    try {
      _stopConnectionTimer();
      _stopStatsTimer();
      
      final success = await FlutterVPNService.stopVPN();
      
      if (success) {
        _setConnected(false);
        _setConnecting(false);
        _setError(null);
        _connectionTime = null;
        _connectionStartTime = null;
        _upText = null;
        _downText = null;
        
        onConnectionTimeChanged?.call(_connectionTime);
        onUploadSpeedChanged?.call(_upText);
        onDownloadSpeedChanged?.call(_downText);
        
        await Logger.logInfo('Flutter VPN断开连接成功');
      }
      
    } catch (e) {
      await Logger.logError('Flutter VPN断开连接异常', e);
    }
  }
  
  /// 获取连接状态
  static Future<Map<String, dynamic>> getConnectionStatus() async {
    try {
      final status = await FlutterVPNService.getVPNStatus();
      final stats = await FlutterVPNService.getConnectionStats();
      
      return {
        'isConnected': status['isConnected'] ?? false,
        'isConnecting': _isConnecting,
        'connectionTime': _connectionTime,
        'uploadSpeed': stats['uploadSpeed'] ?? '0 B/s',
        'downloadSpeed': stats['downloadSpeed'] ?? '0 B/s',
        'uploadBytes': stats['uploadBytes'] ?? 0,
        'downloadBytes': stats['downloadBytes'] ?? 0,
        'error': _errorMessage,
      };
    } catch (e) {
      await Logger.logError('获取连接状态失败', e);
      return {
        'isConnected': false,
        'isConnecting': false,
        'error': e.toString(),
      };
    }
  }
  
  /// 启动连接计时器
  static void _startConnectionTimer() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isConnected && _connectionStartTime != null) {
        final now = DateTime.now();
        final duration = now.difference(_connectionStartTime!);
        _connectionTime = _formatDuration(duration);
        onConnectionTimeChanged?.call(_connectionTime);
      } else if (!_isConnected) {
        _connectionTime = null;
        onConnectionTimeChanged?.call(_connectionTime);
        timer.cancel();
      }
    });
  }
  
  /// 停止连接计时器
  static void _stopConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }
  
  /// 启动统计计时器
  static void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isConnected) {
        try {
          final stats = await FlutterVPNService.getConnectionStats();
          _upText = stats['uploadSpeed'] ?? '0 B/s';
          _downText = stats['downloadSpeed'] ?? '0 B/s';
          
          onUploadSpeedChanged?.call(_upText);
          onDownloadSpeedChanged?.call(_downText);
        } catch (e) {
          // 忽略统计错误
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  /// 停止统计计时器
  static void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }
  
  /// 设置连接状态
  static void _setConnected(bool connected) {
    _isConnected = connected;
    onConnectionStateChanged?.call(connected);
  }
  
  /// 设置连接中状态
  static void _setConnecting(bool connecting) {
    _isConnecting = connecting;
    onConnectingStateChanged?.call(connecting);
  }
  
  /// 设置错误信息
  static void _setError(String? error) {
    _errorMessage = error;
    onErrorChanged?.call(error);
  }
  
  /// 格式化时长
  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
  
  /// 释放资源
  static void dispose() {
    _vpnStatusSub?.cancel();
    _stopConnectionTimer();
    _stopStatsTimer();
  }
  
  // Getter方法
  static bool get isConnected => _isConnected;
  static bool get isConnecting => _isConnecting;
  static String? get connectionTime => _connectionTime;
  static String? get upText => _upText;
  static String? get downText => _downText;
  static String? get errorMessage => _errorMessage;
}
