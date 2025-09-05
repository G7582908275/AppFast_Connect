import 'package:flutter/material.dart';
import '../utils/font_constants.dart';

class StatusCard extends StatelessWidget {
  final bool isConnected;
  final String? connectionTime;
  final String? upText;
  final String? downText;

  const StatusCard({
    super.key,
    required this.isConnected,
    this.connectionTime,
    this.upText,
    this.downText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isConnected ? '已连接' : '未连接',
                style: AppTextStyles.subtitle.copyWith(
                  color: isConnected ? Colors.green : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 连接时间
          Row(
            children: [
              Text(
                '连接时间: ',
                style: AppTextStyles.value.copyWith(color: Colors.grey),
              ),
              Text(
                connectionTime ?? 'N/A',
                style: AppTextStyles.value.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 上传速度
          Row(
            children: [
              Text(
                '上传加速: ',
                style: AppTextStyles.value.copyWith(color: Colors.grey),
              ),
              Text(
                upText ?? 'N/A',
                style: AppTextStyles.value.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 下载速度
          Row(
            children: [
              Text(
                '下载加速: ',
                style: AppTextStyles.value.copyWith(color: Colors.grey),
              ),
              Text(
                downText ?? 'N/A',
                style: AppTextStyles.value.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 0),
        ],
      ),
    );
  }
}
