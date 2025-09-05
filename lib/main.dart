import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/main_screen.dart';

// 条件导入平台特定代码
import 'platforms/macos.dart' if (dart.library.html) 'platforms/web.dart';
import 'platforms/windows.dart' as windows;
import 'platforms/linux.dart' as linux;
import 'platforms/ios.dart' as ios;
import 'platforms/android.dart' as android;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 根据平台调用相应的初始化函数
  if (kIsWeb) {
    await initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    await android.initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    await ios.initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    await initializePlatform();
  } else if (defaultTargetPlatform == TargetPlatform.windows) {
    await windows.initializePlatform();
  } else {
    // Linux 或其他平台
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
