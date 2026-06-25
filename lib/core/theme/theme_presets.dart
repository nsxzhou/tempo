import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'tempo_theme_extension.dart';

enum TempoThemeId {
  minimalWhite,
  deepSpace,
  warmSun,
  mint,
  starry;

  String get storageKey => name;

  String get label => switch (this) {
    TempoThemeId.minimalWhite => '极简白',
    TempoThemeId.deepSpace => '深空黑',
    TempoThemeId.warmSun => '暖阳',
    TempoThemeId.mint => '薄荷',
    TempoThemeId.starry => '星空',
  };

  static TempoThemeId fromStorage(String? value) {
    return TempoThemeId.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TempoThemeId.minimalWhite,
    );
  }
}

class TempoThemePresets {
  TempoThemePresets._();

  static TempoTokens tokensFor(TempoThemeId id) => switch (id) {
    TempoThemeId.minimalWhite => minimalWhite,
    TempoThemeId.deepSpace => deepSpace,
    TempoThemeId.warmSun => warmSun,
    TempoThemeId.mint => mint,
    TempoThemeId.starry => starry,
  };

  static TempoTokens get minimalWhite => TempoTokens(
    bg: AppTheme.bg,
    bgSubtle: AppTheme.bgSubtle,
    bgMuted: AppTheme.bgMuted,
    fg: AppTheme.fg,
    fgSecondary: AppTheme.fgSecondary,
    fgMuted: AppTheme.fgMuted,
    fgSubtle: AppTheme.fgSubtle,
    fgFaint: AppTheme.fgFaint,
    borderSubtle: AppTheme.borderSubtle,
    borderStrong: AppTheme.borderStrong,
    borderEmphasis: AppTheme.borderEmphasis,
    success: AppTheme.success,
    successBg: AppTheme.successBg,
    systemUi: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AppTheme.bg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    taskCardBackground: AppTheme.bg,
  );

  static TempoTokens get deepSpace => TempoTokens(
    bg: const Color(0xFF0A0A0A),
    bgSubtle: const Color(0xFF141414),
    bgMuted: const Color(0xFF1F1F1F),
    fg: const Color(0xFFFAFAFA),
    fgSecondary: const Color(0xFFE4E4E7),
    fgMuted: const Color(0xFFA1A1AA),
    fgSubtle: const Color(0xFF71717A),
    fgFaint: const Color(0xFF52525B),
    borderSubtle: const Color(0xFF1F1F1F),
    borderStrong: const Color(0xFF2E2E2E),
    borderEmphasis: const Color(0xFF3F3F46),
    success: const Color(0xFF34D399),
    successBg: const Color(0xFF064E3B),
    systemUi: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: const Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    taskCardBackground: const Color(0xFF0A0A0A),
  );

  static TempoTokens get warmSun => TempoTokens(
    bg: const Color(0xFFFAF6F0),
    bgSubtle: const Color(0xFFF5EFE6),
    bgMuted: const Color(0xFFEDE4D6),
    fg: const Color(0xFF3D2B1F),
    fgSecondary: const Color(0xFF5C4033),
    fgMuted: const Color(0xFF8B7355),
    fgSubtle: const Color(0xFFA89078),
    fgFaint: const Color(0xFFC4B5A5),
    borderSubtle: const Color(0xFFEDE4D6),
    borderStrong: const Color(0xFFD4C4B0),
    borderEmphasis: const Color(0xFFC4B5A5),
    success: const Color(0xFF059669),
    successBg: const Color(0xFFECFDF5),
    systemUi: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: const Color(0xFFFAF6F0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    taskCardBackground: const Color(0xFFFAF6F0),
  );

  static TempoTokens get mint => TempoTokens(
    bg: const Color(0xFFF0FAF4),
    bgSubtle: const Color(0xFFE8F5EE),
    bgMuted: const Color(0xFFD8EDE3),
    fg: const Color(0xFF1A3D2E),
    fgSecondary: const Color(0xFF2D5A45),
    fgMuted: const Color(0xFF5A8A72),
    fgSubtle: const Color(0xFF7AA892),
    fgFaint: const Color(0xFFA8C4B8),
    borderSubtle: const Color(0xFFD8EDE3),
    borderStrong: const Color(0xFFB8D4C4),
    borderEmphasis: const Color(0xFF9EC4B0),
    success: const Color(0xFF059669),
    successBg: const Color(0xFFD1FAE5),
    systemUi: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: const Color(0xFFF0FAF4),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    taskCardBackground: const Color(0xFFF0FAF4),
  );

  static TempoTokens get starry => TempoTokens(
    bg: const Color(0xFF0F172A),
    bgSubtle: const Color(0xFF1E293B),
    bgMuted: const Color(0xFF334155),
    fg: const Color(0xFFE2E8F0),
    fgSecondary: const Color(0xFFCBD5E1),
    fgMuted: const Color(0xFF94A3B8),
    fgSubtle: const Color(0xFF64748B),
    fgFaint: const Color(0xFF475569),
    borderSubtle: const Color(0xFF1E293B),
    borderStrong: const Color(0xFF334155),
    borderEmphasis: const Color(0xFF475569),
    success: const Color(0xFF818CF8),
    successBg: const Color(0xFF312E81),
    systemUi: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: const Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    taskCardBackground: const Color(0xFF0F172A),
  );
}
