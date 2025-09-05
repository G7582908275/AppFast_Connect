import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../services/vpn_service.dart';
import '../services/tray_service.dart';
import '../utils/font_constants.dart';
import '../utils/permission_utils.dart';
import '../utils/platform_utils.dart';
import '../widgets/password_dialog.dart';
import '../widgets/subscription_card.dart';
import '../widgets/status_card.dart';
import '../widgets/connection_button.dart';
import '../widgets/copyright.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WindowListener {
  bool isConnected = false;
  bool isConnecting = false;
  bool isDisconnecting = false;
  bool hasSubscriptionError = false;
  String _subscriptionId = '';
  late TextEditingController _subscriptionController;
  String? connectionTime;
  String? upText;
  String? downText;
  
  // Connection manager
  late ConnectionManager _connectionManager;

  @override
  void initState() {
    super.initState();
    _subscriptionController = TextEditingController();
    _subscriptionController.addListener(_onSubscriptionTextChanged);
    _loadSettings();
    _initializeConnectionManager();
    _setupPasswordCallback();
    _cleanupOnStartup();
    _setupWindowEvents();
  }

  void _onSubscriptionTextChanged() {
    if (hasSubscriptionError && _subscriptionController.text.trim().isNotEmpty) {
      setState(() {
        hasSubscriptionError = false;
      });
    }
  }

  void _initializeConnectionManager() {
    _connectionManager = ConnectionManager(
      onConnectionStateChanged: (connected) {
        setState(() {
          isConnected = connected;
          // 当连接状态改变时，重置断开状态
          if (!connected) {
            isDisconnecting = false;
          }
        });
      },
      onConnectingStateChanged: (connecting) => setState(() => isConnecting = connecting),
      onConnectionTimeChanged: (time) => setState(() => connectionTime = time),
      onUploadSpeedChanged: (speed) => setState(() => upText = speed),
      onDownloadSpeedChanged: (speed) => setState(() => downText = speed),
      onErrorChanged: (error) {
        if (error != null) {
          // 显示错误消息给用户
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error,
                style: AppTextStyles.value.copyWith(color: Colors.white), 
              ),
              backgroundColor: Colors.grey,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onDispose: () {},
    );
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subscriptionId = prefs.getString('subscription_id') ?? '';
      _subscriptionController.text = _subscriptionId;
    });
  }

  void _setupPasswordCallback() {
    PermissionUtils.setPasswordInputCallback((message) async {
      return await PasswordDialogHelper.showPasswordDialog(
        context,
        title: '输入管理员密码',
        message: message,
      );
    });
  }

  void _cleanupOnStartup() async {
    try {
      await PlatformUtils.cleanupExecutableFiles();
    } catch (e) {
      // 忽略清理错误，不影响应用启动
    }
  }

  void _setupWindowEvents() {
    // 添加窗口监听器
    windowManager.addListener(this);
  }

  @override
  void onWindowClose() async {
    // 隐藏窗口而不是关闭应用
    try {
      await TrayService.hideWindow();
    } catch (e) {
      debugPrint('隐藏窗口到托盘失败: $e');
      // 如果隐藏失败，至少确保窗口关闭
      await windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E), // 深蓝灰色背景
      body: Container(
        color: const Color(0xFF2A2A3E),
        child: Column(
          children: [
            // 应用程序标题
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '网连网络 全球加速',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 主内容卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // 第一个卡片：订阅序号输入
                  SubscriptionCard(
                    controller: _subscriptionController,
                    hasError: hasSubscriptionError,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 第二个卡片：网络状态
                  StatusCard(
                    isConnected: isConnected,
                    connectionTime: connectionTime,
                    upText: upText,
                    downText: downText,
                  ),
                ],
              ),
            ),
            
            // 占位空间，将连接按钮推到底部
            const Expanded(child: SizedBox()),
            
            // 连接按钮 - 底部对齐
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ModernConnectionButton(
                isConnected: isConnected,
                isConnecting: isConnecting,
                isDisconnecting: isDisconnecting,
                onConnect: () async {
                  // 检查订阅序号是否为空
                  if (_subscriptionController.text.trim().isEmpty) {
                    setState(() {
                      hasSubscriptionError = true;
                    });
                    return;
                  }
                  
                  // 清除错误状态
                  setState(() {
                    hasSubscriptionError = false;
                  });
                  
                  // 连接前保存订阅序号
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('subscription_id', _subscriptionController.text);
                  setState(() {
                    _subscriptionId = _subscriptionController.text;
                  });
                  _connectionManager.connect();
                },
                onDisconnect: () {
                  setState(() {
                    isDisconnecting = true;
                  });
                  _connectionManager.disconnect();
                },
              ),
            ),
            
            // 版权信息
            CopyrightWidget(subscriptionId: _subscriptionId),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscriptionController.removeListener(_onSubscriptionTextChanged);
    _subscriptionController.dispose();
    
    // 移除窗口监听器
    windowManager.removeListener(this);
    
    // 注意：dispose只在应用真正退出时调用，不是窗口关闭时
    // 窗口关闭时应该保留VPN连接和托盘图标
    super.dispose();
  }
}
