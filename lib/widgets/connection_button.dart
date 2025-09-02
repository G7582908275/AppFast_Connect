import 'package:flutter/material.dart';
import '../utils/font_constants.dart';

class ModernConnectionButton extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const ModernConnectionButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isConnected 
              ? [Colors.red.shade600, Colors.red.shade700]
              : [Colors.blue.shade600, Colors.blue.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: (isConnected ? Colors.red : Colors.blue).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isConnecting ? null : (isConnected ? onDisconnect : onConnect),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isConnecting) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '连接中...',
                style: AppTextStyles.value.copyWith(color: Colors.white),
              ),
            ] else ...[
              Icon(
                isConnected ? Icons.power_settings_new : Icons.power,
                size: 28,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Text(
                isConnected ? '断开连接' : '连接',
                style: AppTextStyles.value.copyWith(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
