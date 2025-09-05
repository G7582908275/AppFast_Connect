import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'screens/main_screen.dart';

// 条件导入平台特定代码
import 'platforms/macos.dart' if (dart.library.html) 'platforms/web.dart';
import 'platforms/windows.dart' as windows;
import 'platforms/linux.dart' as linux;
import 'platforms/ios.dart' as ios;
import 'platforms/android.dart' as android;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 添加平台调试信息
  print('=== 平台调试信息 ===');
  print('kIsWeb: $kIsWeb');
  print('defaultTargetPlatform: $defaultTargetPlatform');
  print('Platform.isWindows: ${Platform.isWindows}');
  print('Platform.isMacOS: ${Platform.isMacOS}');
  print('Platform.isLinux: ${Platform.isLinux}');
  print('Platform.isAndroid: ${Platform.isAndroid}');
  print('Platform.isIOS: ${Platform.isIOS}');
  print('==================');

  // 根据平台调用相应的初始化函数
  if (kIsWeb) {
    print('调用Web平台初始化');
    await initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    print('调用Android平台初始化');
    await android.initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    print('调用iOS平台初始化');
    await ios.initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    print('调用macOS平台初始化');
    await initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.windows) {
    print('调用Windows平台初始化');
    await windows.initializePlatform();
  } else {
    // Linux 或其他平台
    print('调用Linux平台初始化');
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
