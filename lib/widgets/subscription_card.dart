import 'package:flutter/material.dart';
import '../utils/font_constants.dart';

class SubscriptionCard extends StatefulWidget {
  final TextEditingController controller;
  final bool hasError;

  const SubscriptionCard({
    super.key, 
    required this.controller,
    this.hasError = false,
  });

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  bool _obscureText = true;

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
          Text(
            '服务码',
            style: AppTextStyles.subtitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            obscureText: _obscureText,
            style: AppTextStyles.value,
            decoration: InputDecoration(
              hintText: widget.hasError ? '请输入服务码' : '请输入服务码',
              hintStyle: AppTextStyles.label.copyWith(
                color: widget.hasError ? Colors.red[300] : null,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.hasError 
                      ? Colors.red.withValues(alpha: 0.7)
                      : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.hasError 
                      ? Colors.red.withValues(alpha: 0.7)
                      : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.hasError 
                      ? Colors.red.withValues(alpha: 0.9)
                      : Colors.blue.withValues(alpha: 0.7),
                ),
              ),
              filled: true,
              fillColor: widget.hasError 
                  ? Colors.red.withValues(alpha: 0.1)
                  : const Color(0xFF1E1E2E),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
