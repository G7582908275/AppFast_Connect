import 'package:flutter/material.dart';
import '../utils/font_constants.dart';

class LocationCard extends StatelessWidget {
  final String? exitLocation;
  final String? exitIP;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const LocationCard({
    super.key,
    this.exitLocation,
    this.exitIP,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    // 出口位置和刷新按钮
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  icon: Icons.public,
                  label: '出口国家',
                  value: exitLocation ?? '未连接',
                  isLoading: isLoading,
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isLoading ? Icons.hourglass_empty : Icons.refresh,
                      color: Colors.blue,
                      size: 18,
                    ),
                    onPressed: isLoading ? null : onRefresh,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 出口IP
          _buildInfoRow(
            icon: Icons.computer,
            label: '出口地址',
            value: exitIP ?? '未连接',
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isLoading,
  }) {
    return Row(
      children: [
        // 图标
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        
        // 标签和值
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,

                style: AppTextStyles.value.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              
              // 值或加载状态
              if (isLoading)
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Checking...',
                      style: AppTextStyles.value
                    ),
                  ],
                )
              else
                Text(
                  value,
                  style: AppTextStyles.value.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w100,
                    color: value == '未连接' ? Colors.grey : Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
