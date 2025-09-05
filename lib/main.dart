import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'screens/main_screen.dart';
import 'services/process_service.dart';

// 条件导入平台特定代码
import 'platforms/macos.dart' if (dart.library.html) 'platforms/web.dart';
import 'platforms/windows.dart' as windows;
import 'platforms/linux.dart' as linux;
import 'platforms/ios.dart' as ios;
import 'platforms/android.dart' as android;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 检查应用是否已经在运行
  final isAlreadyRunning = await ProcessService.isAlreadyRunning();
  
  if (isAlreadyRunning) {
    // 如果应用已在运行，尝试激活现有实例
    final activated = await ProcessService.activateExistingInstance();
    if (activated) {
      print('应用已在运行，已激活现有窗口');
      exit(0); // 退出新启动的实例
    } else {
      print('应用已在运行，但无法激活现有窗口');
      exit(0); // 仍然退出新启动的实例
    }
  }

  // 创建锁文件，标记应用正在运行
  await ProcessService.createLockFile();

  // 根据平台调用相应的初始化函数
  if (kIsWeb) {
    await initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    await android.initializePlatform();
    await ios.initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    await initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.windows) {
    await windows.initializePlatform();
  } else {
    await linux.initializePlatform();
  }

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
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
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
