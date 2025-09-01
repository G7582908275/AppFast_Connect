import 'package:flutter/material.dart';
import '../utils/font_constants.dart';
import '../utils/permission_utils.dart';

class SubscriptionCard extends StatefulWidget {
  final String initialSubscriptionId;
  final Function(String) onSave;
  final VoidCallback onCancel;

  const SubscriptionCard({
    super.key,
    required this.initialSubscriptionId,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  late final TextEditingController _subscriptionController;
  bool _hasSavedPassword = false;

  @override
  void initState() {
    super.initState();
    _subscriptionController = TextEditingController(text: widget.initialSubscriptionId);
    _checkSavedPassword();
  }

  @override
  void dispose() {
    _subscriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    widget.onSave(_subscriptionController.text);
  }

  Future<void> _checkSavedPassword() async {
    final hasPassword = await PermissionUtils.hasSavedPassword();
    setState(() {
      _hasSavedPassword = hasPassword;
    });
  }

  Future<void> _clearPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          '清除保存的密码',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '确定要清除保存的管理员密码吗？\n\n清除后，下次连接VPN时需要重新输入密码。',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await PermissionUtils.clearSavedPassword();
      if (success) {
        setState(() {
          _hasSavedPassword = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('密码已清除'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('清除密码失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
                                   const Text(
                       '设置',
                       style: AppTextStyles.subtitle,
                     ),
            ],
          ),
          const SizedBox(height: 24),
                           Text(
                   '订阅序号',
                   style: AppTextStyles.label.copyWith(color: Colors.grey.shade400),
                 ),
          const SizedBox(height: 12),
          TextField(
            controller: _subscriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '请输入订阅序号',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.7)),
              ),
              filled: true,
              fillColor: const Color(0xFF1E1E2E),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
                    const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 清除密码按钮
              if (_hasSavedPassword)
                TextButton.icon(
                  onPressed: _clearPassword,
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  label: Text(
                    '清除密码',
                    style: AppTextStyles.label.copyWith(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              if (_hasSavedPassword) const SizedBox(width: 12),
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  '取消',
                  style: AppTextStyles.label.copyWith(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '保存',
                  style: AppTextStyles.value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
