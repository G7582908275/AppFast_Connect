import 'package:flutter/material.dart';
import '../utils/font_constants.dart';

class SubscriptionCard extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;

  const SubscriptionCard({
    super.key, 
    required this.controller,
    this.hasError = false,
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
          // 订阅序号标签
          Text(
            '订阅序号',
            style: AppTextStyles.subtitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          // 订阅序号输入框
          TextField(
            controller: controller,
            style: AppTextStyles.value,
            decoration: InputDecoration(
              hintText: hasError ? '请输入订阅序号' : '请输入订阅序号',
              hintStyle: AppTextStyles.label.copyWith(
                color: hasError ? Colors.red[300] : null,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError 
                      ? Colors.red.withValues(alpha: 0.7)
                      : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError 
                      ? Colors.red.withValues(alpha: 0.7)
                      : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError 
                      ? Colors.red.withValues(alpha: 0.9)
                      : Colors.blue.withValues(alpha: 0.7),
                ),
              ),
              filled: true,
              fillColor: hasError 
                  ? Colors.red.withValues(alpha: 0.1)
                  : const Color(0xFF1E1E2E),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
