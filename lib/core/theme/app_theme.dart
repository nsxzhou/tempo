// ============================================================
// Tempo App 主题 — Stripe 派极致工艺
// 字体三件套(Geist Sans/Mono + Instrument Serif) + 黑白灰
// + P0/P1/P2/绿 4 语义色。完全对齐 prototype/src/index.css。
// ============================================================

import 'package:flutter/material.dart';

/// Tempo 应用主题与设计 token
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════
  // 字体三件套
  // ═══════════════════════════════════════════════════════════

  /// 主字体 — Geist Sans(对应 prototype `--font-sans`)
  static const String fontSans = 'Geist';

  /// 等宽字体 — Geist Mono(数字/时间/邮箱/占比)
  static const String fontMono = 'Geist Mono';

  /// 衬线斜体 — Instrument Serif(详情页大标题/用户头像)
  static const String fontSerif = 'Instrument Serif';

  // ═══════════════════════════════════════════════════════════
  // 配色 token(完整对应 prototype/src/index.css :root)
  // ═══════════════════════════════════════════════════════════

  /// Surface(背景)
  static const Color bg = Color(0xFFFFFFFF);
  static const Color bgSubtle = Color(0xFFFAFAFA);
  static const Color bgMuted = Color(0xFFF4F4F5);

  /// Foreground(文本)
  static const Color fg = Color(0xFF0A0A0A);
  static const Color fgSecondary = Color(0xFF18181B);
  static const Color fgMuted = Color(0xFF71717A);
  static const Color fgSubtle = Color(0xFFA1A1AA);
  static const Color fgFaint = Color(0xFFD4D4D8);

  /// Border(边线)
  static const Color borderSubtle = Color(0xFFF4F4F5);
  static const Color borderStrong = Color(0xFFE4E4E7);
  static const Color borderEmphasis = Color(0xFFD4D4D8);

  /// 优先级色(对齐 prototype)
  static const Color priorityP0 = Color(0xFFDC2626);
  static const Color priorityP0Bg = Color(0xFFFEF2F2);
  static const Color priorityP0Border = Color(0xFFFECACA);

  static const Color priorityP1 = Color(0xFFD97706);
  static const Color priorityP1Bg = Color(0xFFFFFBEB);
  static const Color priorityP1Border = Color(0xFFFED7AA);

  static const Color priorityP2 = Color(0xFF2563EB);
  static const Color priorityP2Bg = Color(0xFFEFF6FF);
  static const Color priorityP2Border = Color(0xFFBFDBFE);

  static const Color priorityP3 = Color(0xFF71717A);
  static const Color priorityP3Bg = Color(0xFFF4F4F5);
  static const Color priorityP3Border = Color(0xFFE4E4E7);

  /// 状态色
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  /// 强调靛蓝(原型"MVP 验证期"徽章/indigo 点缀)
  static const Color accentIndigo = Color(0xFF4338CA);
  static const Color accentIndigoBg = Color(0xFFEEF2FF);
  static const Color accentIndigoBorder = Color(0xFFE0E7FF);
  static const Color accentIndigoFg = Color(0xFF818CF8);

  /// 兼容旧名(勿在新代码使用)— 暂保留以减少改动面
  static const Color errorColor = priorityP0;
  static const Color warningColor = priorityP1;
  static const Color successColor = success;
  static const Color infoColor = priorityP2;

  /// primary 已切换为 fg(黑色)。旧 import 仍能跑,视觉从紫变黑。
  static const Color primaryColor = fg;
  static const Color primaryLight = bgMuted;

  // ═══════════════════════════════════════════════════════════
  // 圆角 token
  // ═══════════════════════════════════════════════════════════

  static const double radiusXxxs = 3;
  static const double radiusXxs = 4;
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ═══════════════════════════════════════════════════════════
  // 间距 token(8px 网格)
  // ═══════════════════════════════════════════════════════════

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;

  /// 所有页面主区域水平内边距(对应 prototype `px-5`)
  static const double pageHorizontalPadding = 20;

  // ═══════════════════════════════════════════════════════════
  // 阴影 token
  // ═══════════════════════════════════════════════════════════

  /// 卡片极弱选中阴影(对应 Tailwind `shadow-2xs`,segmented 选中态)
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// 卡片极弱阴影(对应 Tailwind `shadow-sm`)
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  /// 选中态双圈阴影(对应 prototype `shadow-[0_0_0_3px_#FFFFFF,0_0_0_4.5px_#0A0A0A]`)
  static const List<BoxShadow> shadowSelectedDot = [
    BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 0, spreadRadius: 3),
    BoxShadow(color: Color(0xFF0A0A0A), blurRadius: 0, spreadRadius: 4.5),
  ];

  // ═══════════════════════════════════════════════════════════
  // 主题
  // ═══════════════════════════════════════════════════════════

  /// 亮色主题
  static ThemeData get light {
    // 基础文本:Geist(已通过 pubspec 字体块落地,无需系统回退)
    final baseTextTheme = ThemeData.light().textTheme.apply(
          fontFamily: fontSans,
          bodyColor: fg,
          displayColor: fg,
        );

    // Instrument Serif Italic(已落地)用于 display/headline 大标题与详情
    TextStyle serifItalic(TextStyle? base) => base?.copyWith(
          fontFamily: fontSerif,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          color: fg,
        ) ??
        const TextStyle(fontFamily: fontSerif, fontStyle: FontStyle.italic);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // 黑色为基色,Material 3 colorScheme 偏中性
      colorScheme: ColorScheme.fromSeed(
        seedColor: fg,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: fontSans, // 全局默认 Geist (fallback 到系统 sans-serif)
      textTheme: baseTextTheme.copyWith(
        displayLarge: serifItalic(baseTextTheme.displayLarge),
        displayMedium: serifItalic(baseTextTheme.displayMedium),
        displaySmall: serifItalic(baseTextTheme.displaySmall),
        headlineLarge: serifItalic(baseTextTheme.headlineLarge),
        headlineMedium: serifItalic(baseTextTheme.headlineMedium),
        headlineSmall: serifItalic(baseTextTheme.headlineSmall),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: fg),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: fgSecondary),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: fgMuted),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: fg),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: fg),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: fg),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: fg),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: bg,
        surfaceTintColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderStrong),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: fg, size: 20),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: bgMuted,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: fg,
        foregroundColor: bg,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: fg,
          foregroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: const BorderSide(color: borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: fg,
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: fg, width: 2),
        ),
        filled: true,
        fillColor: bg,
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: fgSubtle),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space4,
          vertical: space3,
        ),
      ),
    );
  }

  /// 暗色主题(Phase 2)
  static ThemeData get dark {
    // TODO: 实现暗色主题
    return ThemeData.dark(useMaterial3: true);
  }

  // ═══════════════════════════════════════════════════════════
  // 工具方法
  // ═══════════════════════════════════════════════════════════

  /// 根据优先级返回对应颜色(原型 P0/P1/P2/P3)
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
        return fgMuted;
    }
  }

  /// 返回优先级对应的徽章底色(bg)
  static Color priorityBg(int priority) {
    switch (priority) {
      case 1:
        return priorityP0Bg;
      case 2:
        return priorityP1Bg;
      case 3:
        return priorityP2Bg;
      case 4:
        return priorityP3Bg;
      default:
        return bgMuted;
    }
  }

  /// 返回优先级对应的徽章边线(border)
  static Color priorityBorder(int priority) {
    switch (priority) {
      case 1:
        return priorityP0Border;
      case 2:
        return priorityP1Border;
      case 3:
        return priorityP2Border;
      case 4:
        return priorityP3Border;
      default:
        return borderStrong;
    }
  }

  /// Instrument Serif Italic 快捷构造(详情页/计划页大标题)
  static TextStyle italicSerif({
    double size = 32,
    FontWeight weight = FontWeight.w400,
    Color color = fg,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontSerif,
      fontStyle: FontStyle.italic,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Geist Mono 快捷构造(数字/时间/邮箱)
  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = fg,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontMono,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Geist Sans Bold H1 快捷构造(任务页 TODO 等主 Tab 大标题)
  static TextStyle sansBold({
    double size = 32,
    Color color = fg,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontSans,
      fontWeight: FontWeight.w700,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Geist Sans SemiBold H1 快捷构造(日历等主 Tab 大标题)
  static TextStyle sansSemibold({
    double size = 32,
    Color color = fg,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontSans,
      fontWeight: FontWeight.w600,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
