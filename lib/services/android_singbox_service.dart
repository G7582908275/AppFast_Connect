import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Android sing-box VPN服务
class AndroidSingBoxService {
  static Process? _singBoxProcess;
  static bool _isConnected = false;
  static const String _singBoxBinary = 'sing-box';
  
  /// 启动sing-box服务
  static Future<bool> startSingBox({
    required String configPath,
    required String subscriptionId,
  }) async {
    try {
      if (kIsWeb) return false;
      
      await Logger.logInfo('开始启动Android sing-box服务...');
      
      // 获取订阅配置
      final config = await _generateSingBoxConfig(subscriptionId);
      if (config == null) {
        await Logger.logError('无法生成sing-box配置');
        return false;
      }
      
      // 写入配置文件
      final configFile = File(configPath);
      await configFile.writeAsString(config);
      await Logger.logInfo('sing-box配置文件已写入: $configPath');
      
      // 启动sing-box进程
      _singBoxProcess = await Process.start(
        _singBoxBinary,
        ['run', '-c', configPath],
        workingDirectory: Directory.current.path,
      );
      
      // 等待启动
      final started = await _waitForStartup();
      if (started) {
        _isConnected = true;
        await Logger.logInfo('Android sing-box服务启动成功');
        return true;
      } else {
        await Logger.logError('Android sing-box服务启动失败');
        return false;
      }
      
    } catch (e) {
      await Logger.logError('启动Android sing-box服务异常', e);
      return false;
    }
  }
  
  /// 生成sing-box配置
  static Future<String?> _generateSingBoxConfig(String subscriptionId) async {
    try {
      // 基础配置模板
      final config = {
        "log": {
          "level": "info",
          "timestamp": true
        },
        "inbounds": [
          {
            "type": "tun",
            "tag": "tun-in",
            "interface_name": "tun0",
            "auto_route": true,
            "auto_detect_interface": true,
            "stack": "system",
            "mptcp": false,
            "strict_route": false,
            "sniff": true
          }
        ],
        "outbounds": [
          {
            "type": "selector",
            "tag": "proxy",
            "outbounds": ["auto", "direct"]
          },
          {
            "type": "urltest",
            "tag": "auto",
            "outbounds": ["proxy-1"],
            "url": "https://www.gstatic.com/generate_204",
            "interval": "300s"
          },
          {
            "type": "direct",
            "tag": "direct"
          }
        ],
        "route": {
          "rules": [
            {
              "geoip": "private",
              "outbound": "direct"
            },
            {
              "geosite": "category-ads-all",
              "outbound": "block"
            }
          ]
        }
      };
      
      // 添加代理配置
      final proxyConfig = await _getProxyConfig(subscriptionId);
      if (proxyConfig != null) {
        (config["outbounds"] as List).insert(1, proxyConfig);
      }
      
      return json.encode(config);
      
    } catch (e) {
      await Logger.logError('生成sing-box配置失败', e);
      return null;
    }
  }
  
  /// 获取代理配置
  static Future<Map<String, dynamic>?> _getProxyConfig(String subscriptionId) async {
    try {
      // 这里应该从您的API获取代理配置
      // 示例配置
      return {
        "type": "shadowsocks",
        "tag": "proxy-1",
        "server": "your-server.com",
        "server_port": 443,
        "method": "aes-256-gcm",
        "password": "your-password"
      };
    } catch (e) {
      await Logger.logError('获取代理配置失败', e);
      return null;
    }
  }
  
  /// 等待sing-box启动
  static Future<bool> _waitForStartup() async {
    try {
      // 监听sing-box输出
      _singBoxProcess!.stdout.transform(utf8.decoder).listen((data) {
        Logger.logInfo('sing-box输出: $data');
      });
      
      _singBoxProcess!.stderr.transform(utf8.decoder).listen((data) {
        Logger.logWarning('sing-box错误: $data');
      });
      
      // 等待一段时间检查进程是否正常
      await Future.delayed(const Duration(seconds: 3));
      
      // 检查进程是否还在运行
      final exitCode = await _singBoxProcess!.exitCode.timeout(
        const Duration(seconds: 1),
        onTimeout: () => -1,
      );
      
      return exitCode == -1; // -1表示进程仍在运行
      
    } catch (e) {
      await Logger.logError('等待sing-box启动失败', e);
      return false;
    }
  }
  
  /// 停止sing-box服务
  static Future<bool> stopSingBox() async {
    try {
      if (_singBoxProcess != null) {
        _singBoxProcess!.kill();
        await _singBoxProcess!.exitCode;
        _singBoxProcess = null;
      }
      
      _isConnected = false;
      await Logger.logInfo('Android sing-box服务已停止');
      return true;
      
    } catch (e) {
      await Logger.logError('停止Android sing-box服务失败', e);
      return false;
    }
  }
  
  /// 检查连接状态
  static bool get isConnected => _isConnected;
  
  /// 获取连接状态
  static Future<bool> checkConnectionStatus() async {
    if (_singBoxProcess == null) {
      _isConnected = false;
      return false;
    }
    
    try {
      final exitCode = await _singBoxProcess!.exitCode.timeout(
        const Duration(seconds: 1),
        onTimeout: () => -1,
      );
      
      _isConnected = exitCode == -1; // -1表示进程仍在运行
      return _isConnected;
      
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }
}
