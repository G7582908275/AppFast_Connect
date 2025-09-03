import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

// 仅在非Web平台导入这些包

// 条件导入平台特定代码
import 'main_desktop.dart' if (dart.library.html) 'main_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 调用平台特定的初始化函数
  await initializePlatform();

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
