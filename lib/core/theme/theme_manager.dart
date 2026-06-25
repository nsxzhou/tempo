import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'tempo_theme_extension.dart';
import 'theme_presets.dart';

/// 单套主题下的组件色 override。
class ThemeComponentColors {
  final Color? taskCardColor;
  final Color? headerColor;

  const ThemeComponentColors({this.taskCardColor, this.headerColor});

  ThemeComponentColors copyWith({Color? taskCardColor, Color? headerColor}) {
    return ThemeComponentColors(
      taskCardColor: taskCardColor ?? this.taskCardColor,
      headerColor: headerColor ?? this.headerColor,
    );
  }
}

class ThemeCustomizationState {
  final TempoThemeId themeId;
  final String? backgroundImagePath;
  final bool backgroundImageValid;
  final ThemeComponentColors componentColors;

  const ThemeCustomizationState({
    required this.themeId,
    this.backgroundImagePath,
    this.backgroundImageValid = false,
    this.componentColors = const ThemeComponentColors(),
  });

  ThemeCustomizationState copyWith({
    TempoThemeId? themeId,
    String? backgroundImagePath,
    bool? backgroundImageValid,
    bool clearBackground = false,
    ThemeComponentColors? componentColors,
  }) {
    return ThemeCustomizationState(
      themeId: themeId ?? this.themeId,
      backgroundImagePath: clearBackground
          ? null
          : (backgroundImagePath ?? this.backgroundImagePath),
      backgroundImageValid: clearBackground
          ? false
          : (backgroundImageValid ?? this.backgroundImageValid),
      componentColors: componentColors ?? this.componentColors,
    );
  }
}

bool _backgroundImageExists(String? path) {
  if (path == null) return false;
  return File(path).existsSync();
}

class ThemeManager extends StateNotifier<ThemeCustomizationState> {
  ThemeManager()
    : super(const ThemeCustomizationState(themeId: TempoThemeId.minimalWhite)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = TempoThemeId.fromStorage(
      prefs.getString(AppConstants.prefThemeId),
    );
    final bgPath = prefs.getString(AppConstants.prefBackgroundImagePath);
    final taskCard = prefs.getInt(
      '${AppConstants.prefTaskCardColorPrefix}${themeId.name}',
    );
    final header = prefs.getInt(
      '${AppConstants.prefHeaderColorPrefix}${themeId.name}',
    );

    state = ThemeCustomizationState(
      themeId: themeId,
      backgroundImagePath: bgPath,
      backgroundImageValid: _backgroundImageExists(bgPath),
      componentColors: ThemeComponentColors(
        taskCardColor: taskCard != null ? Color(taskCard) : null,
        headerColor: header != null ? Color(header) : null,
      ),
    );
  }

  Future<void> setTheme(TempoThemeId id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeId, id.name);

    final taskCard = prefs.getInt(
      '${AppConstants.prefTaskCardColorPrefix}${id.name}',
    );
    final header = prefs.getInt(
      '${AppConstants.prefHeaderColorPrefix}${id.name}',
    );

    state = state.copyWith(
      themeId: id,
      componentColors: ThemeComponentColors(
        taskCardColor: taskCard != null ? Color(taskCard) : null,
        headerColor: header != null ? Color(header) : null,
      ),
    );
  }

  Future<void> pickBackgroundImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final docs = await getApplicationDocumentsDirectory();
    final backgroundsDir = Directory(p.join(docs.path, 'backgrounds'));
    if (!backgroundsDir.existsSync()) {
      backgroundsDir.createSync(recursive: true);
    }

    final ext = p.extension(file.path);
    final destPath = p.join(
      backgroundsDir.path,
      'bg_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(file.path).copy(destPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefBackgroundImagePath, destPath);

    state = state.copyWith(
      backgroundImagePath: destPath,
      backgroundImageValid: true,
    );
  }

  Future<void> clearBackgroundImage() async {
    final path = state.backgroundImagePath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefBackgroundImagePath);
    state = state.copyWith(clearBackground: true);
  }

  Future<void> setTaskCardColor(Color? color) async {
    await _persistComponentColor(
      key: '${AppConstants.prefTaskCardColorPrefix}${state.themeId.name}',
      color: color,
      update: (colors) => colors.copyWith(taskCardColor: color),
    );
  }

  Future<void> setHeaderColor(Color? color) async {
    await _persistComponentColor(
      key: '${AppConstants.prefHeaderColorPrefix}${state.themeId.name}',
      color: color,
      update: (colors) => colors.copyWith(headerColor: color),
    );
  }

  Future<void> resetComponentColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      '${AppConstants.prefTaskCardColorPrefix}${state.themeId.name}',
    );
    await prefs.remove(
      '${AppConstants.prefHeaderColorPrefix}${state.themeId.name}',
    );
    state = state.copyWith(componentColors: const ThemeComponentColors());
  }

  Future<void> _persistComponentColor({
    required String key,
    required Color? color,
    required ThemeComponentColors Function(ThemeComponentColors) update,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, color.toARGB32());
    }
    state = state.copyWith(componentColors: update(state.componentColors));
  }
}

final themeManagerProvider =
    StateNotifierProvider<ThemeManager, ThemeCustomizationState>((ref) {
      return ThemeManager();
    });

final activeTempoTokensProvider = Provider<TempoTokens>((ref) {
  final customization = ref.watch(themeManagerProvider);
  var tokens = TempoThemePresets.tokensFor(customization.themeId);
  final hasBg = customization.backgroundImageValid;
  if (hasBg) {
    tokens = tokens.copyWith(backgroundOverlayOpacity: 0.28);
  }
  final custom = customization.componentColors.taskCardColor;
  Color taskCardBg;
  if (custom != null) {
    taskCardBg = hasBg ? custom.withValues(alpha: 0.65) : custom;
  } else if (hasBg) {
    taskCardBg = _glassFillAlpha(tokens.bg);
  } else {
    taskCardBg = tokens.bg;
  }
  return tokens.copyWith(taskCardBackground: taskCardBg);
});

/// 毛玻璃表面样式（有自定义背景时启用 blur + 半透明 fill）。
class GlassSurfaceStyle {
  final bool enabled;
  final double blurSigma;
  final Color fillColor;
  final Color borderColor;
  final Color solidColor;

  const GlassSurfaceStyle({
    required this.enabled,
    required this.blurSigma,
    required this.fillColor,
    required this.borderColor,
    required this.solidColor,
  });

  factory GlassSurfaceStyle.solid({
    required Color color,
    required Color border,
  }) {
    return GlassSurfaceStyle(
      enabled: false,
      blurSigma: 0,
      fillColor: color,
      borderColor: border,
      solidColor: color,
    );
  }
}

Color _glassFillAlpha(Color base, {double? lightAlpha, double? darkAlpha}) {
  final brightness = ThemeData.estimateBrightnessForColor(base);
  final alpha = brightness == Brightness.dark
      ? (darkAlpha ?? 0.42)
      : (lightAlpha ?? 0.58);
  return base.withValues(alpha: alpha);
}

final glassSurfaceStyleProvider = Provider<GlassSurfaceStyle>((ref) {
  final tokens = ref.watch(activeTempoTokensProvider);
  if (!ref.watch(hasCustomBackgroundProvider)) {
    return GlassSurfaceStyle.solid(
      color: tokens.bg,
      border: tokens.borderStrong,
    );
  }
  return GlassSurfaceStyle(
    enabled: true,
    blurSigma: 16,
    fillColor: _glassFillAlpha(tokens.bg),
    borderColor: tokens.borderStrong.withValues(alpha: 0.45),
    solidColor: tokens.bg,
  );
});

/// 有自定义背景图时 Scaffold 须透明，否则会盖住 [TempoBackground]。
final hasCustomBackgroundProvider = Provider<bool>((ref) {
  return ref.watch(themeManagerProvider).backgroundImageValid;
});

final scaffoldBackgroundProvider = Provider<Color>((ref) {
  if (ref.watch(hasCustomBackgroundProvider)) {
    return Colors.transparent;
  }
  return ref.watch(activeTempoTokensProvider).bg;
});

final taskCardBackgroundProvider = Provider<Color>((ref) {
  return ref.watch(activeTempoTokensProvider).taskCardBackground;
});

final headerBackgroundProvider = Provider<Color>((ref) {
  final customization = ref.watch(themeManagerProvider);
  final tokens = ref.watch(activeTempoTokensProvider);
  final hasBg = ref.watch(hasCustomBackgroundProvider);
  final custom = customization.componentColors.headerColor;
  if (custom != null) {
    return hasBg ? custom.withValues(alpha: 0.35) : custom;
  }
  if (hasBg) {
    return Colors.transparent;
  }
  return tokens.bg;
});
