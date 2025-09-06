import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';
import '../services/vpn_service.dart';
import '../services/tray_service.dart';
import '../utils/font_constants.dart';
import '../utils/platform_utils.dart';
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
  
  // 托盘图标监控定时器
  Timer? _trayMonitorTimer;

  @override
  void initState() {
    super.initState();
    _subscriptionController = TextEditingController();
    _subscriptionController.addListener(_onSubscriptionTextChanged);
    _loadSettings();
    _initializeConnectionManager();
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
    
    // 启动托盘图标监控
    _startTrayMonitoring();
  }
  
  /// 启动托盘图标监控
  void _startTrayMonitoring() {
    // 每30秒检查一次托盘图标状态
    _trayMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkTrayIconStatus();
    });
  }
  
  /// 检查托盘图标状态
  void _checkTrayIconStatus() async {
    try {
      // 只有在窗口隐藏时才检查托盘图标
      if (!TrayService.isWindowVisible) {
        debugPrint('检查托盘图标状态...');
        // 简化检查逻辑，直接尝试恢复托盘图标
        await TrayService.recoverTrayIcon();
      }
    } catch (e) {
      debugPrint('检查托盘图标状态时发生错误: $e');
    }
  }

  @override
  void onWindowClose() async {
    // 隐藏窗口而不是关闭应用
    try {
      debugPrint('窗口关闭事件触发，隐藏窗口到托盘');
      
      // 确保托盘服务已初始化
      if (TrayService.isWindowVisible) {
        debugPrint('窗口当前可见，准备隐藏到托盘');
      } else {
        debugPrint('窗口可能已经隐藏，确保托盘服务正常');
        await TrayService.recoverTrayIcon();
      }
      
      // 隐藏窗口到托盘
      await TrayService.hideWindow();
      
      debugPrint('窗口已成功隐藏到托盘，应用继续在后台运行');
    } catch (e) {
      debugPrint('隐藏窗口到托盘失败: $e');
      
      // 如果隐藏失败，尝试强制隐藏但保持应用运行
      try {
        await windowManager.hide();
        debugPrint('强制隐藏窗口成功，应用继续在后台运行');
      } catch (e2) {
        debugPrint('强制隐藏窗口也失败: $e2');
        // 即使隐藏失败，也不应该退出应用
        debugPrint('应用将继续在后台运行，即使窗口隐藏失败');
      }
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
    
    // 停止托盘监控定时器
    _trayMonitorTimer?.cancel();
    
    // 移除窗口监听器
    windowManager.removeListener(this);
    
    // 注意：dispose只在应用真正退出时调用，不是窗口关闭时
    // 窗口关闭时应该保留VPN连接和托盘图标
    super.dispose();
  }
}
