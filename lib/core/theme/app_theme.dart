import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tempo 应用主题
class AppTheme {
  AppTheme._();

  // ── 品牌色 ──
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color primaryLight = Color(0xFFEEF2FF);

  // ── 语义色 ──
  static const Color successColor = Color(0xFF059669);
  static const Color warningColor = Color(0xFFD97706);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color infoColor = Color(0xFF2563EB);

  // ── 优先级色 ──
  static const Color priorityP0 = Color(0xFFDC2626); // 红
  static const Color priorityP1 = Color(0xFFF59E0B); // 橙
  static const Color priorityP2 = Color(0xFF2563EB); // 蓝
  static const Color priorityP3 = Color(0xFF6B7280); // 灰

  /// 亮色主题
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: primaryColor,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade500,
      ),
    );
  }

  /// 暗色主题（Phase 2）
  static ThemeData get dark {
    // TODO: 实现暗色主题
    return ThemeData.dark(useMaterial3: true);
  }

  /// 根据优先级返回对应颜色
  static Color priorityColor(int priority) {
    switch (priority) {
      case 1:
        return priorityP0;
      case 2:
        return priorityP1;
      case 3:
        return priorityP2;
      case 4:
        return priorityP3;
      default:
        return Colors.grey;
    }
  }
}
