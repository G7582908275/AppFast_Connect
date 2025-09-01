import 'package:flutter/material.dart';

/// 字体常量类，定义类似 Speedtest 应用的字体策略
class AppFonts {
  // 主要标题字体 - 使用 SF Pro Display 或系统字体
  static const String titleFont = 'SF Pro Display, PingFang SC, Helvetica Neue, sans-serif';
  
  // 数值显示字体 - 使用等宽字体
  static const String numberFont = 'SF Mono, Monaco, Consolas, monospace';
  
  // 标签文字字体 - 使用系统字体
  static const String labelFont = 'SF Pro Text, PingFang SC, Helvetica Neue, sans-serif';
  
  // 中文优先字体 - 确保中文显示效果
  static const String chineseFont = 'PingFang SC, Hiragino Sans GB, Microsoft YaHei, sans-serif';
  
  // 混合字体 - 英文使用西文字体，中文使用中文字体
  static const String mixedFont = 'SF Pro Display, PingFang SC, Helvetica Neue, sans-serif';
}

/// 字体样式常量
class AppTextStyles {
  // 主要标题样式
  static const TextStyle title = TextStyle(
    fontFamily: AppFonts.titleFont,
    fontSize: 24,
    fontWeight: FontWeight.w100,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // 副标题样式
  static const TextStyle subtitle = TextStyle(
    fontFamily: AppFonts.titleFont,
    fontSize: 20,
    fontWeight: FontWeight.w100,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // 数值显示样式
  static const TextStyle number = TextStyle(
    fontFamily: AppFonts.numberFont,
    fontSize: 18,
    fontWeight: FontWeight.w100,
    color: Colors.white,
  );
  
  // 标签样式
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.labelFont,
    fontSize: 16,
    fontWeight: FontWeight.w100,
    color: Colors.grey,
  );
  
  // 值样式
  static const TextStyle value = TextStyle(
    fontFamily: AppFonts.labelFont,
    fontSize: 16,
    fontWeight: FontWeight.w100,
    color: Colors.white,
  );
  
  // 按钮文字样式
  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.titleFont,
    fontSize: 18,
    fontWeight: FontWeight.w100,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // 小标签样式
  static const TextStyle smallLabel = TextStyle(
    fontFamily: AppFonts.labelFont,
    fontSize: 24,
    fontWeight: FontWeight.w100,
    color: Colors.grey,
  );

  static const TextStyle numberValue = TextStyle(
    fontFamily: AppFonts.numberFont,
    fontSize: 24,
    fontWeight: FontWeight.w100,
    color: Colors.white,
  );
}

/// 格式化工具类
class FormatUtils {
  /// 格式化比特率显示
  static String formatBitsPerSecond(int bytesPerSec) {
    // Convert to bits per second
    final int bitsPerSec = bytesPerSec * 8;
    const units = ['b/s', 'Kb/s', 'Mb/s', 'Gb/s'];
    double value = bitsPerSec.toDouble();
    int unitIndex = 0;
    while (value >= 1000 && unitIndex < units.length - 1) {
      value /= 1000;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value < 10 ? 2 : 1)} ${units[unitIndex]}';
  }

  /// 格式化持续时间显示
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
