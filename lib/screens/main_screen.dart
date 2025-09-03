import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/vpn_service.dart';
import '../widgets/subscription_card.dart';
import '../widgets/status_card.dart';
import '../widgets/connection_button.dart';
import '../utils/font_constants.dart';
import '../utils/permission_utils.dart';
import '../utils/platform_utils.dart';
import '../widgets/password_dialog.dart';
import '../widgets/location_card.dart';
import '../services/location_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isConnected = false;
  bool isConnecting = false;
  String? connectionTime;
  String? upText;
  String? downText;
  String? errorMessage;
  String? exitLocation;
  String? exitIP;
  bool isLocationLoading = false;
  
  // Settings state
  bool _showSettings = false;
  String _subscriptionId = '';
  
  // Connection manager
  late ConnectionManager _connectionManager;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeConnectionManager();
    _setupPasswordCallback();
    _getInitialLocationInfo();
    _cleanupOnStartup();
  }

  void _initializeConnectionManager() {
    _connectionManager = ConnectionManager(
      onConnectionStateChanged: (connected) {
        setState(() => isConnected = connected);
        // 无论连接还是断开，都更新位置信息
        _updateLocationInfo();
      },
      onConnectingStateChanged: (connecting) => setState(() => isConnecting = connecting),
      onConnectionTimeChanged: (time) => setState(() => connectionTime = time),
      onUploadSpeedChanged: (speed) => setState(() => upText = speed),
      onDownloadSpeedChanged: (speed) => setState(() => downText = speed),
      onErrorChanged: (error) => setState(() => errorMessage = error),
      onDispose: () {},
    );
  }

  void _getInitialLocationInfo() async {
    setState(() {
      isLocationLoading = true;
    });
    
    try {
      final locationInfo = await LocationService.getExitInfo();
      
      if (locationInfo != null) {
        setState(() {
          exitLocation = locationInfo['location'];
          exitIP = locationInfo['ip'];
          isLocationLoading = false;
        });
      } else {
        setState(() {
          exitLocation = '获取失败';
          exitIP = '获取失败';
          isLocationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        exitLocation = '获取失败';
        exitIP = '获取失败';
        isLocationLoading = false;
      });
    }
  }

  void _updateLocationInfo() async {
    setState(() {
      isLocationLoading = true;
    });
    
    try {
      // 使用真实的位置服务获取出口信息
      final locationInfo = await LocationService.getExitInfo();
      
      if (locationInfo != null) {
        setState(() {
          exitLocation = locationInfo['location'];
          exitIP = locationInfo['ip'];
          isLocationLoading = false;
        });
      } else {
        setState(() {
          exitLocation = '获取失败';
          exitIP = '获取失败';
          isLocationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        exitLocation = '获取失败';
        exitIP = '获取失败';
        isLocationLoading = false;
      });
    }
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subscriptionId = prefs.getString('subscription_id') ?? '';
    });
  }

  void _openSettings() {
    setState(() {
      _showSettings = true;
    });
  }

  void _setupPasswordCallback() {
    PermissionUtils.setPasswordInputCallback((message) async {
      return await PasswordDialogHelper.showPasswordDialog(
        context,
        title: '输入密码',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E), // 深蓝灰色背景
      appBar: AppBar(
        title: const Text(
          'WideWired AppFast',
          style: AppTextStyles.title,
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1E1E2E),
        child: Column(
          children: [
            // 位置卡片 - 顶部对齐
            if (!_showSettings)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: LocationCard(
                  exitLocation: exitLocation,
                  exitIP: exitIP,
                  isLoading: isLocationLoading,
                  onRefresh: _updateLocationInfo,
                ),
              ),
            
            // 状态卡片
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _showSettings
                  ? SubscriptionCard(
                      initialSubscriptionId: _subscriptionId,
                      onSave: (String subscriptionId) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('subscription_id', subscriptionId);
                        setState(() {
                          _subscriptionId = subscriptionId;
                          _showSettings = false;
                        });
                      },
                      onCancel: () {
                        setState(() {
                          _showSettings = false;
                        });
                      },
                    )
                  : ModernStatusCard(
                      isConnected: isConnected,
                      connectionTime: connectionTime,
                      upText: upText,
                      downText: downText,
                      errorMessage: errorMessage,
                    ),
            ),
            
            // 占位空间，将连接按钮推到底部
            const Expanded(child: SizedBox()),
            
            // 连接按钮 - 底部对齐（仅在非设置状态下显示）
            if (!_showSettings)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ModernConnectionButton(
                  isConnected: isConnected,
                  isConnecting: isConnecting,
                  onConnect: () => _connectionManager.connect(),
                  onDisconnect: () => _connectionManager.disconnect(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectionManager.dispose();
    super.dispose();
  }
}
