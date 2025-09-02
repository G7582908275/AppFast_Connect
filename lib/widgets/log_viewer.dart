import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

class LogViewerDialog extends StatefulWidget {
  const LogViewerDialog({super.key});

  @override
  State<LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends State<LogViewerDialog> {
  String _logContent = '';
  bool _isLoading = true;
  String? _logFilePath;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');
      
      if (await logDir.exists()) {
        final files = await logDir.list().toList();
        final logFiles = files.where((f) => f.path.endsWith('.log')).toList();
        
        if (logFiles.isNotEmpty) {
          // 获取最新的日志文件
          logFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
          final latestLog = logFiles.first as File;
          _logFilePath = latestLog.path;
          
          final content = await latestLog.readAsString();
          setState(() {
            _logContent = content;
            _isLoading = false;
          });
        } else {
          setState(() {
            _logContent = '没有找到日志文件';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _logContent = '日志目录不存在';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _logContent = '加载日志失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    try {
      await Logger.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志已清除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除日志失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '应用日志',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_logFilePath != null)
                      Text(
                        '文件: ${_logFilePath!.split('/').last}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _loadLogs,
                      child: const Text('刷新'),
                    ),
                    TextButton(
                      onPressed: _clearLogs,
                      child: const Text('清除'),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _logContent,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LogUtils {
  /// 显示日志查看器对话框
  static void showLogViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LogViewerDialog(),
    );
  }
}
