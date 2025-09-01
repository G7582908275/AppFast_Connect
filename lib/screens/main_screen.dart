import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/vpn_service.dart';
import '../widgets/subscription_card.dart';
import '../widgets/status_card.dart';
import '../widgets/connection_button.dart';
import '../utils/font_constants.dart';

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
  }

  void _initializeConnectionManager() {
    _connectionManager = ConnectionManager(
      onConnectionStateChanged: (connected) => setState(() => isConnected = connected),
      onConnectingStateChanged: (connecting) => setState(() => isConnecting = connecting),
      onConnectionTimeChanged: (time) => setState(() => connectionTime = time),
      onUploadSpeedChanged: (speed) => setState(() => upText = speed),
      onDownloadSpeedChanged: (speed) => setState(() => downText = speed),
      onDispose: () {},
    );
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
            // 状态卡片 - 顶部对齐
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
