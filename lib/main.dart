import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/main_screen.dart';

// 条件导入平台特定代码
import 'main_desktop.dart' if (dart.library.html) 'main_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 根据平台调用相应的初始化函数
  if (kIsWeb) {
    await initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.android || 
             defaultTargetPlatform == TargetPlatform.iOS) {
    // 移动平台使用简化的初始化
    await initializeMobilePlatform();
  } else {
    // 桌面平台
    await initializePlatform();
  }

  runApp(const MyApp());
}

// 移动平台初始化函数
Future<void> initializeMobilePlatform() async {
  print('=== 移动平台应用启动 ===');
  print('移动平台初始化完成');
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
