import 'package:flutter/material.dart';
import '../utils/font_constants.dart';

class ModernStatusCard extends StatelessWidget {
  final bool isConnected;
  final String? connectionTime;
  final String? upText;
  final String? downText;
  final String? errorMessage;

  const ModernStatusCard({
    super.key,
    required this.isConnected,
    this.connectionTime,
    this.upText,
    this.downText,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E), // 稍亮的深蓝灰色
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorMessage != null 
              ? Colors.red.withValues(alpha: 0.3)
              : isConnected ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态标题行
          Row(
            children: [
              Icon(
                errorMessage != null 
                    ? Icons.error
                    : isConnected ? Icons.check_circle : Icons.circle_outlined,
                color: errorMessage != null 
                    ? Colors.red
                    : isConnected ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                errorMessage != null 
                    ? '连接错误'
                    : isConnected ? '已连接' : '未连接',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
          
          // 错误信息显示
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: AppTextStyles.label.copyWith(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (isConnected) ...[
            const SizedBox(height: 24),
            
            // 连接时间
            if (connectionTime != null) ...[
              _buildModernInfoRow('连接时间', connectionTime!, Icons.access_time),
              const SizedBox(height: 16),
            ],
            
            // 流量信息
            if (upText != null || downText != null) ...[
              _buildModernInfoRow('上传速度', upText ?? '--', Icons.upload),
              const SizedBox(height: 12),
              _buildModernInfoRow('下载速度', downText ?? '--', Icons.download),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: AppTextStyles.subtitle,
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.value,
          ),
        ),
      ],
    );
  }
}
