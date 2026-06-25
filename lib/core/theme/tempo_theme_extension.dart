import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'theme_presets.dart';

/// 运行时主题 token（通过 ThemeExtension 注入）。
class TempoTokens extends ThemeExtension<TempoTokens> {
  final Color bg;
  final Color bgSubtle;
  final Color bgMuted;
  final Color fg;
  final Color fgSecondary;
  final Color fgMuted;
  final Color fgSubtle;
  final Color fgFaint;
  final Color borderSubtle;
  final Color borderStrong;
  final Color borderEmphasis;
  final Color success;
  final Color successBg;
  final SystemUiOverlayStyle systemUi;
  final double backgroundOverlayOpacity;
  final Color taskCardBackground;

  const TempoTokens({
    required this.bg,
    required this.bgSubtle,
    required this.bgMuted,
    required this.fg,
    required this.fgSecondary,
    required this.fgMuted,
    required this.fgSubtle,
    required this.fgFaint,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderEmphasis,
    required this.success,
    required this.successBg,
    required this.systemUi,
    this.backgroundOverlayOpacity = 0.0,
    required this.taskCardBackground,
  });

  Color priorityColor(int priority) => AppTheme.priorityColor(priority);

  Color priorityBg(int priority) => AppTheme.priorityBg(priority);

  Color priorityBorder(int priority) => AppTheme.priorityBorder(priority);

  TextStyle italicSerif({
    double size = 32,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => AppTheme.italicSerif(
    size: size,
    weight: weight,
    color: color ?? fg,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => AppTheme.mono(
    size: size,
    weight: weight,
    color: color ?? fg,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle sansSemibold({
    double size = 32,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => AppTheme.sansSemibold(
    size: size,
    color: color ?? fg,
    height: height,
    letterSpacing: letterSpacing,
  );

  ThemeData toThemeData() {
    final brightness = _brightness;
    final baseTextTheme = ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: AppTheme.fontSans,
      bodyColor: fg,
      displayColor: fg,
    );

    TextStyle serifItalic(TextStyle? base) =>
        base?.copyWith(
          fontFamily: AppTheme.fontSerif,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          color: fg,
        ) ??
        TextStyle(
          fontFamily: AppTheme.fontSerif,
          fontStyle: FontStyle.italic,
          color: fg,
        );

    final textTheme = baseTextTheme.copyWith(
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
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: fg,
      brightness: brightness,
      surface: bg,
      onSurface: fg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundOverlayOpacity > 0
          ? Colors.transparent
          : bg,
      fontFamily: AppTheme.fontSans,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: fg,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: fg),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: bg,
        surfaceTintColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: borderStrong),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: fg, size: 20),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: bgMuted,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: fg),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return bg;
          return fgSubtle;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return fg;
          return bgMuted;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return fg;
            return bgMuted;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return bg;
            return fgMuted;
          }),
          side: WidgetStateProperty.all(BorderSide(color: borderStrong)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
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
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: fg,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: fg, width: 2),
        ),
        filled: true,
        fillColor: bg,
        hintStyle: textTheme.bodyMedium?.copyWith(color: fgSubtle),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space3,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: bg,
      ),
      dialogTheme: DialogThemeData(backgroundColor: bg, surfaceTintColor: bg),
      extensions: [this],
    );
  }

  Brightness get _brightness =>
      bg.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark;

  @override
  TempoTokens copyWith({
    Color? bg,
    Color? bgSubtle,
    Color? bgMuted,
    Color? fg,
    Color? fgSecondary,
    Color? fgMuted,
    Color? fgSubtle,
    Color? fgFaint,
    Color? borderSubtle,
    Color? borderStrong,
    Color? borderEmphasis,
    Color? success,
    Color? successBg,
    SystemUiOverlayStyle? systemUi,
    double? backgroundOverlayOpacity,
    Color? taskCardBackground,
  }) {
    return TempoTokens(
      bg: bg ?? this.bg,
      bgSubtle: bgSubtle ?? this.bgSubtle,
      bgMuted: bgMuted ?? this.bgMuted,
      fg: fg ?? this.fg,
      fgSecondary: fgSecondary ?? this.fgSecondary,
      fgMuted: fgMuted ?? this.fgMuted,
      fgSubtle: fgSubtle ?? this.fgSubtle,
      fgFaint: fgFaint ?? this.fgFaint,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      borderEmphasis: borderEmphasis ?? this.borderEmphasis,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      systemUi: systemUi ?? this.systemUi,
      backgroundOverlayOpacity:
          backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      taskCardBackground: taskCardBackground ?? this.taskCardBackground,
    );
  }

  @override
  TempoTokens lerp(ThemeExtension<TempoTokens>? other, double t) {
    if (other is! TempoTokens) return this;
    return TempoTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSubtle: Color.lerp(bgSubtle, other.bgSubtle, t)!,
      bgMuted: Color.lerp(bgMuted, other.bgMuted, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fgSecondary: Color.lerp(fgSecondary, other.fgSecondary, t)!,
      fgMuted: Color.lerp(fgMuted, other.fgMuted, t)!,
      fgSubtle: Color.lerp(fgSubtle, other.fgSubtle, t)!,
      fgFaint: Color.lerp(fgFaint, other.fgFaint, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderEmphasis: Color.lerp(borderEmphasis, other.borderEmphasis, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      systemUi: t < 0.5 ? systemUi : other.systemUi,
      backgroundOverlayOpacity:
          backgroundOverlayOpacity +
          (other.backgroundOverlayOpacity - backgroundOverlayOpacity) * t,
      taskCardBackground: Color.lerp(
        taskCardBackground,
        other.taskCardBackground,
        t,
      )!,
    );
  }
}

extension TempoThemeContext on BuildContext {
  TempoTokens get tokens =>
      Theme.of(this).extension<TempoTokens>() ?? TempoThemePresets.minimalWhite;
}
