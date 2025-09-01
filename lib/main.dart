import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/main_screen.dart';
import 'utils/permission_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 在 macOS 上，首先检查并请求管理员权限
  if (Platform.isMacOS) {
    final hasPermissions = await PermissionUtils.ensureRequiredPermissions();
    if (!hasPermissions) {
      exit(1);
    }
  }

  // 设置窗口属性
  await windowManager.ensureInitialized();

  // 设置窗口尺寸为200x550，并禁用调整大小
  await windowManager.setSize(const Size(400, 609));
  await windowManager.setResizable(false);
  await windowManager.setMinimumSize(const Size(400, 609));
  await windowManager.setMaximumSize(const Size(400, 609));

  // 设置窗口标题
  await windowManager.setTitle('');
  await windowManager.show();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WideWired Connect Manager',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
