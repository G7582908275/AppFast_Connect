import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/main_screen.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:window_manager/window_manager.dart';

// 条件导入平台特定代码
import 'platforms/macos.dart' if (dart.library.html) 'platforms/web.dart';
import 'platforms/windows.dart' as windows;
import 'platforms/linux.dart' as linux;
import 'platforms/ios.dart' as ios;
import 'platforms/android.dart' as android;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 首先进行单实例检查（在平台初始化之前）
  if (await FlutterSingleInstance().isFirstInstance()) {
    // 只有第一个实例才进行平台初始化
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
  } else {
    debugPrint("App is already running");

    // 如果窗体隐藏，则需要显示出来
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      try {
        await windowManager.show();
        await windowManager.focus();
      } catch (e) {
        // 忽略异常，继续执行
        debugPrint("Error showing window: $e");
      }
    }
    final err = await FlutterSingleInstance().focus();

    if (err != null) {
      debugPrint("Error focusing running instance: $err");
    }

    exit(0);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
