import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

class LocationService {
  // 多个API端点作为备用
  static const List<String> _apiEndpoints = [
    'https://ipapi.co/json',           // 主要API，免费1000次/天
    'http://ip-api.com/json',          // 备用API，免费45次/分钟
    'https://ipapi.com/json',          // 备用API，免费1000次/天
    'https://ipinfo.io/json',          // 原API作为最后备用
  ];
  
  /// 获取完整的出口信息（IP + 位置）
  static Future<Map<String, String>?> getExitInfo() async {
    for (int i = 0; i < _apiEndpoints.length; i++) {
      final endpoint = _apiEndpoints[i];
      try {
        await Logger.logInfo('尝试获取出口信息 (API ${i + 1}): $endpoint');
        
        final response = await http.get(Uri.parse(endpoint)).timeout(
          const Duration(seconds: 5), // 减少超时时间
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // 根据不同API的响应格式解析数据
          final result = _parseApiResponse(data, endpoint);
          if (result != null) {
            await Logger.logInfo('成功获取出口信息 (API ${i + 1}): ${result['location']} - ${result['ip']}');
            return result;
          }
        } else {
          await Logger.logWarning('API ${i + 1} 返回错误状态码: ${response.statusCode}');
        }
      } catch (e) {
        await Logger.logWarning('API ${i + 1} 请求失败: $e');
        continue; // 尝试下一个API
      }
    }
    
    await Logger.logError('所有API都失败了，无法获取出口信息');
    return null;
  }
  
  /// 解析不同API的响应格式
  static Map<String, String>? _parseApiResponse(Map<String, dynamic> data, String endpoint) {
    try {
      String? ip, city, region, country, org;
      
      if (endpoint.contains('ipapi.co')) {
        // ipapi.co 格式
        ip = data['ip'] as String?;
        city = data['city'] as String?;
        region = data['region'] as String?;
        country = data['country_name'] as String?;
        org = data['org'] as String?;
      } else if (endpoint.contains('ip-api.com')) {
        // ip-api.com 格式
        ip = data['query'] as String?;
        city = data['city'] as String?;
        region = data['regionName'] as String?;
        country = data['country'] as String?;
        org = data['isp'] as String?;
      } else if (endpoint.contains('ipapi.com')) {
        // ipapi.com 格式
        ip = data['ip'] as String?;
        city = data['city'] as String?;
        region = data['region'] as String?;
        country = data['country'] as String?;
        org = data['org'] as String?;
      } else if (endpoint.contains('ipinfo.io')) {
        // ipinfo.io 格式
        ip = data['ip'] as String?;
        city = data['city'] as String?;
        region = data['region'] as String?;
        country = data['country'] as String?;
        org = data['org'] as String?;
      }
      
      // 验证必要字段
      if (ip == null || ip.isEmpty) {
        return null;
      }
      
      // 构建位置信息
      String location = country ?? '未知';
      if (region != null && region.isNotEmpty) {
        location += ', $region';
      }
      if (city != null && city.isNotEmpty) {
        location += ', $city';
      }
      
      return {
        'location': location,
        'ip': ip,
        'isp': org ?? '未知',
      };
    } catch (e) {
      Logger.logError('解析API响应失败: $e');
      return null;
    }
  }
  
  /// 仅获取IP地址（使用最稳定的API）
  static Future<String?> getIpAddress() async {
    try {
      // 使用httpbin.org作为最稳定的IP获取源
      final response = await http.get(Uri.parse('https://httpbin.org/ip')).timeout(
        const Duration(seconds: 3),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ip = data['origin'] as String?;
        if (ip != null && ip.isNotEmpty) {
          await Logger.logInfo('成功获取IP地址: $ip');
          return ip;
        }
      }
    } catch (e) {
      await Logger.logWarning('获取IP地址失败: $e');
    }
    
    // 备用方案：尝试其他API
    final exitInfo = await getExitInfo();
    return exitInfo?['ip'];
  }
}
