import 'package:flutter/material.dart';
import 'dart:io';

/// 字体常量类，根据不同操作系统提供最佳字体配置
class AppFonts {
  // macOS 字体配置
  static const String _macOSTitleFont = 'SF Pro Display, Helvetica Neue, Arial, sans-serif';
  static const String _macOSNumberFont = 'SF Mono, Monaco, Consolas, monospace';
  static const String _macOSLabelFont = 'SF Pro Text, Helvetica Neue, Arial, sans-serif';
  static const String _macOSChineseFont = 'PingFang SC, Hiragino Sans GB, sans-serif';
  
  // Windows 字体配置
  static const String _windowsTitleFont = 'Segoe UI, Microsoft YaHei UI, Arial, sans-serif';
  static const String _windowsNumberFont = 'Consolas, Courier New, monospace';
  static const String _windowsLabelFont = 'Segoe UI, Microsoft YaHei UI, Arial, sans-serif';
  static const String _windowsChineseFont = 'Microsoft YaHei, SimHei, sans-serif';
  
  // Linux 字体配置
  static const String _linuxTitleFont = 'Ubuntu, Cantarell, Liberation Sans, Arial, sans-serif';
  static const String _linuxNumberFont = 'Ubuntu Mono, Liberation Mono, Consolas, monospace';
  static const String _linuxLabelFont = 'Ubuntu, Cantarell, Liberation Sans, Arial, sans-serif';
  static const String _linuxChineseFont = 'Noto Sans CJK SC, WenQuanYi Micro Hei, sans-serif';
  
  // Android 字体配置
  static const String _androidTitleFont = 'Roboto, Noto Sans CJK SC, Arial, sans-serif';
  static const String _androidNumberFont = 'Roboto Mono, Noto Sans Mono CJK SC, monospace';
  static const String _androidLabelFont = 'Roboto, Noto Sans CJK SC, Arial, sans-serif';
  static const String _androidChineseFont = 'Noto Sans CJK SC, Roboto, sans-serif';
  
  // iOS 字体配置
  static const String _iOSTitleFont = 'SF Pro Display, Helvetica Neue, Arial, sans-serif';
  static const String _iOSNumberFont = 'SF Mono, Monaco, Consolas, monospace';
  static const String _iOSLabelFont = 'SF Pro Text, Helvetica Neue, Arial, sans-serif';
  static const String _iOSChineseFont = 'PingFang SC, Hiragino Sans GB, sans-serif';
  
  // Web 字体配置
  static const String _webTitleFont = 'Inter, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif';
  static const String _webNumberFont = 'JetBrains Mono, Fira Code, Consolas, monospace';
  static const String _webLabelFont = 'Inter, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif';
  static const String _webChineseFont = 'Noto Sans CJK SC, PingFang SC, Microsoft YaHei, sans-serif';

  /// 获取主要标题字体
  static String get titleFont {
    if (Platform.isMacOS) return _macOSTitleFont;
    if (Platform.isWindows) return _windowsTitleFont;
    if (Platform.isLinux) return _linuxTitleFont;
    if (Platform.isAndroid) return _androidTitleFont;
    if (Platform.isIOS) return _iOSTitleFont;
    return _webTitleFont; // Web 或其他平台
  }
  
  /// 获取数值显示字体
  static String get numberFont {
    if (Platform.isMacOS) return _macOSNumberFont;
    if (Platform.isWindows) return _windowsNumberFont;
    if (Platform.isLinux) return _linuxNumberFont;
    if (Platform.isAndroid) return _androidNumberFont;
    if (Platform.isIOS) return _iOSNumberFont;
    return _webNumberFont; // Web 或其他平台
  }
  
  /// 获取标签文字字体
  static String get labelFont {
    if (Platform.isMacOS) return _macOSLabelFont;
    if (Platform.isWindows) return _windowsLabelFont;
    if (Platform.isLinux) return _linuxLabelFont;
    if (Platform.isAndroid) return _androidLabelFont;
    if (Platform.isIOS) return _iOSLabelFont;
    return _webLabelFont; // Web 或其他平台
  }
  
  /// 获取中文优先字体
  static String get chineseFont {
    if (Platform.isMacOS) return _macOSChineseFont;
    if (Platform.isWindows) return _windowsChineseFont;
    if (Platform.isLinux) return _linuxChineseFont;
    if (Platform.isAndroid) return _androidChineseFont;
    if (Platform.isIOS) return _iOSChineseFont;
    return _webChineseFont; // Web 或其他平台
  }
  
  /// 获取混合字体（英文使用西文字体，中文使用中文字体）
  static String get mixedFont {
    if (Platform.isMacOS) return _macOSTitleFont;
    if (Platform.isWindows) return _windowsTitleFont;
    if (Platform.isLinux) return _linuxTitleFont;
    if (Platform.isAndroid) return _androidTitleFont;
    if (Platform.isIOS) return _iOSTitleFont;
    return _webTitleFont; // Web 或其他平台
  }
}

/// 字体样式常量
class AppTextStyles {
  // 主要标题样式
  static TextStyle get title => TextStyle(
    fontFamily: AppFonts.titleFont,
    fontSize: 24,
    fontWeight: FontWeight.w100,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // 副标题样式
  static TextStyle get subtitle => TextStyle(
    fontFamily: AppFonts.titleFont,
    fontSize: 16,
    fontWeight: FontWeight.w100,
    color: Colors.grey,
    letterSpacing: 0.5,
  );
  
  // 数值显示样式
  static TextStyle get number => TextStyle(
    fontFamily: AppFonts.numberFont,
    fontSize: 14,
    fontWeight: FontWeight.w100,
    color: Colors.white,
  );
  
  // 标签样式
  static TextStyle get label => TextStyle(
    fontFamily: AppFonts.labelFont,
    fontSize: 14,
    fontWeight: FontWeight.w100,
    color: Colors.grey,
  );
  
  // 值样式
  static TextStyle get value => TextStyle(
    fontFamily: AppFonts.labelFont,
    fontSize: 16,
    fontWeight: FontWeight.w100,
    color: Colors.white70,
  );
  
  // 按钮文字样式
  static TextStyle get button => TextStyle(
    fontFamily: AppFonts.titleFont,
    fontSize: 14,
    fontWeight: FontWeight.w100,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // 小标签样式
  static TextStyle get smallLabel => TextStyle(
    fontFamily: AppFonts.labelFont,
    fontSize: 14,
    fontWeight: FontWeight.w100,
    color: Colors.grey,
  );

  static TextStyle get numberValue => TextStyle(
    fontFamily: AppFonts.numberFont,
    fontSize: 15,
    fontWeight: FontWeight.w100,
    color: Colors.white,
  );
}

