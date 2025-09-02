import 'package:flutter/material.dart';
import '../utils/font_constants.dart';

class PasswordDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? initialValue;

  const PasswordDialog({
    super.key,
    required this.title,
    required this.message,
    this.initialValue,
  });

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _passwordController.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2E2E3E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        widget.title,
        style: AppTextStyles.subtitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message,
            style: AppTextStyles.value.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTextStyles.value.copyWith(color: Colors.white),
            decoration: InputDecoration(
              labelText: '密码',
              labelStyle: AppTextStyles.value.copyWith(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: AppTextStyles.value.copyWith(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '确定',
            style: AppTextStyles.value.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final password = _passwordController.text.trim();
    if (password.isNotEmpty) {
      Navigator.of(context).pop(password);
    }
  }
}

// 显示密码输入对话框的工具函数
class PasswordDialogHelper {
  static Future<String?> showPasswordDialog(
    BuildContext context, {
    String title = '输入密码',
    String message = '请输入管理员密码:',
    String? initialValue,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(
        title: title,
        message: message,
        initialValue: initialValue,
      ),
    );
  }
}
