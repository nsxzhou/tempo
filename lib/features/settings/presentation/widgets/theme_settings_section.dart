import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/theme/tempo_theme_extension.dart';
import '../../../../core/widgets/tempo/tempo.dart';

class ThemeSettingsSection extends ConsumerWidget {
  const ThemeSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(themeManagerProvider);
    final tokens = context.tokens;
    final manager = ref.read(themeManagerProvider.notifier);
    final hasBackground = customization.backgroundImageValid;

    return TempoSettingsGroup(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      borderColor: tokens.borderStrong,
      dividerColor: tokens.borderSubtle,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THEME · 主题',
                style: tokens.mono(
                  size: 9,
                  color: tokens.fgSubtle,
                  weight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final id in TempoThemeId.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: id != TempoThemeId.values.last ? 6 : 0,
                          left: id != TempoThemeId.values.first ? 6 : 0,
                        ),
                        child: _ThemePresetTile(
                          id: id,
                          selected: customization.themeId == id,
                          onTap: () => manager.setTheme(id),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TempoPreferenceRow(
              icon: LucideIcons.image,
              title: '自定义背景',
              subtitle: hasBackground ? '已设置全屏背景图' : '从相册选择全屏背景',
              trailing: hasBackground
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SettingsPill(
                          label: '已设置',
                          foreground: tokens.success,
                          background: tokens.successBg,
                          border: tokens.success.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 6),
                        _SettingsPill(
                          label: '清除',
                          foreground: tokens.fgMuted,
                          background: tokens.bgMuted,
                          border: tokens.borderStrong,
                          onTap: () => manager.clearBackgroundImage(),
                        ),
                      ],
                    )
                  : _SettingsPill(
                      label: '选择',
                      foreground: tokens.bg,
                      background: tokens.fg,
                      border: tokens.fg,
                      onTap: () => manager.pickBackgroundImage(),
                    ),
            ),
            if (hasBackground)
              Padding(
                padding: const EdgeInsets.fromLTRB(58, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: Image.file(
                      File(customization.backgroundImagePath!),
                      fit: BoxFit.cover,
                      cacheWidth: 192,
                    ),
                  ),
                ),
              ),
          ],
        ),
        _ComponentColorsBlock(
          taskCardColor: customization.componentColors.taskCardColor,
          onTaskCardColor: manager.setTaskCardColor,
        ),
        TempoPreferenceRow(
          icon: LucideIcons.rotate_ccw,
          title: '恢复组件默认色',
          subtitle: '清除当前主题下的卡片配色',
          onTap: () => manager.resetComponentColors(),
        ),
      ],
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  final TempoThemeId id;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePresetTile({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final preset = TempoThemePresets.tokensFor(id);

    return Semantics(
      button: true,
      selected: selected,
      label: id.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: preset.bg,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: selected ? preset.fg : preset.borderStrong,
                  width: selected ? 2 : 0.8,
                ),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: preset.fg,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              id.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tokens.mono(
                size: 9,
                color: selected ? tokens.fg : tokens.fgMuted,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback? onTap;

  const _SettingsPill({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        label,
        style: AppTheme.mono(
          size: 10,
          weight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );

    if (onTap == null) return child;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _ComponentColorsBlock extends ConsumerWidget {
  final Color? taskCardColor;
  final Future<void> Function(Color?) onTaskCardColor;

  const _ComponentColorsBlock({
    required this.taskCardColor,
    required this.onTaskCardColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('组件配色', style: tokens.sansSemibold(size: 12)),
          const SizedBox(height: 12),
          _ComponentColorRow(
            title: '任务卡片背景',
            current: taskCardColor,
            onSelect: onTaskCardColor,
          ),
        ],
      ),
    );
  }
}

class _ComponentColorRow extends ConsumerWidget {
  final String title;
  final Color? current;
  final Future<void> Function(Color?) onSelect;

  const _ComponentColorRow({
    required this.title,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final palette = [
      null,
      tokens.bg,
      tokens.bgSubtle,
      tokens.bgMuted,
      tokens.fg.withValues(alpha: 0.08),
      tokens.successBg,
      tokens.borderStrong,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tokens.mono(
            size: 10,
            color: tokens.fgMuted,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in palette)
              Semantics(
                button: true,
                label: color == null ? '恢复默认' : '选择颜色',
                selected: current == color,
                child: GestureDetector(
                  onTap: () => onSelect(color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color ?? tokens.bg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                      border: Border.all(
                        color: current == color
                            ? tokens.fg
                            : tokens.borderStrong,
                        width: current == color ? 2 : 0.8,
                      ),
                    ),
                    child: color == null
                        ? Icon(LucideIcons.ban, size: 16, color: tokens.fgMuted)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
