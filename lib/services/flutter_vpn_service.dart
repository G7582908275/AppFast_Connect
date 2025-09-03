
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Flutter VPN服务插件
class FlutterVPNService {
  static const MethodChannel _channel = MethodChannel('appfast_connect/vpn');
  static const EventChannel _eventChannel = EventChannel('appfast_connect/vpn_events');
  
  /// 启动VPN服务
  static Future<bool> startVPN({
    required String subscriptionId,
    String? serverAddress,
    int? serverPort,
    String? encryptionMethod,
    String? password,
  }) async {
    try {
      if (kIsWeb) {
        await Logger.logInfo('Web平台不支持VPN服务');
        return false;
      }
      
      final Map<String, dynamic> params = {
        'subscriptionId': subscriptionId,
        'serverAddress': serverAddress,
        'serverPort': serverPort,
        'encryptionMethod': encryptionMethod,
        'password': password,
      };
      
      final bool result = await _channel.invokeMethod('startVPN', params);
      await Logger.logInfo('Flutter VPN服务启动结果: $result');
      return result;
      
    } on PlatformException catch (e) {
      await Logger.logError('启动Flutter VPN服务失败: ${e.message}', e);
      return false;
    }
  }
  
  /// 停止VPN服务
  static Future<bool> stopVPN() async {
    try {
      final bool result = await _channel.invokeMethod('stopVPN');
      await Logger.logInfo('Flutter VPN服务停止结果: $result');
      return result;
    } on PlatformException catch (e) {
      await Logger.logError('停止Flutter VPN服务失败: ${e.message}', e);
      return false;
    }
  }
  
  /// 检查VPN状态
  static Future<Map<String, dynamic>> getVPNStatus() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getVPNStatus');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      await Logger.logError('获取VPN状态失败: ${e.message}', e);
      return {
        'isConnected': false,
        'error': e.message,
      };
    }
  }
  
  /// 监听VPN状态变化
  static Stream<Map<String, dynamic>> get vpnStatusStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }
  
  /// 请求VPN权限
  static Future<bool> requestVPNPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestVPNPermission');
      await Logger.logInfo('VPN权限请求结果: $result');
      return result;
    } on PlatformException catch (e) {
      await Logger.logError('请求VPN权限失败: ${e.message}', e);
      return false;
    }
  }
  
  /// 检查VPN权限
  static Future<bool> checkVPNPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkVPNPermission');
      return result;
    } on PlatformException catch (e) {
      await Logger.logError('检查VPN权限失败: ${e.message}', e);
      return false;
    }
  }
  
  /// 获取连接统计信息
  static Future<Map<String, dynamic>> getConnectionStats() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getConnectionStats');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      await Logger.logError('获取连接统计失败: ${e.message}', e);
      return {
        'uploadBytes': 0,
        'downloadBytes': 0,
        'uploadSpeed': '0 B/s',
        'downloadSpeed': '0 B/s',
      };
    }
  }
}
