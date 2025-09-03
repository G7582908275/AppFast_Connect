import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/font_constants.dart';

class CopyrightWidget extends StatelessWidget {
  final String subscriptionId;
  
  const CopyrightWidget({
    super.key,
    required this.subscriptionId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          // 线路服务信息
          Text(
            '线路服务由中国电信提供',
            style: AppTextStyles.value.copyWith(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          
          // 备案号
          Text(
            '备案号: 京ISA备202305220002',
            style: AppTextStyles.value.copyWith(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          
          // 管理链接
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    final url = 'http://sdn-manager.ipam.zone/v2/$subscriptionId';
                    final uri = Uri.parse(url);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    // 如果无法打开URL，可以显示一个提示
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('无法打开管理网站'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  '管理订阅',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 12,
                    color: Colors.blue[300],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  // TODO: 实现帮助与支持功能
                },
                child: Text(
                  '帮助与支持',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 12,
                    color: Colors.blue[300],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
