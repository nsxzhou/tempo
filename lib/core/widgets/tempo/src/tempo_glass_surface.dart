import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/theme_manager.dart';

/// 自定义背景下的磨砂玻璃表面；无背景时降级为实心 Container。
class TempoGlassSurface extends ConsumerWidget {
  static final Map<int, ImageFilter> _blurCache = {};

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final bool showShadow;

  /// 为 false 时仅使用半透明 fill，不创建 [BackdropFilter]（列表项等高频场景）。
  final bool blur;

  const TempoGlassSurface({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppTheme.radiusLg),
    ),
    this.fillColor,
    this.borderColor,
    this.boxShadow,
    this.showShadow = true,
    this.blur = false,
  });

  static ImageFilter blurFilter(double sigma) {
    final key = (sigma * 100).round();
    return _blurCache.putIfAbsent(
      key,
      () => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(glassSurfaceStyleProvider);
    final resolvedFill =
        fillColor ?? (style.enabled ? style.fillColor : style.solidColor);
    final resolvedBorder = borderColor ?? style.borderColor;
    final shadows = showShadow
        ? (boxShadow ?? (style.enabled ? null : AppTheme.shadowSm))
        : null;

    final decoration = BoxDecoration(
      color: resolvedFill,
      borderRadius: borderRadius,
      border: Border.all(color: resolvedBorder, width: 0.8),
      boxShadow: shadows,
    );

    Widget surface = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (style.enabled && blur) {
      surface = ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: blurFilter(style.blurSigma),
          child: surface,
        ),
      );
    }

    return RepaintBoundary(
      child: Container(margin: margin, child: surface),
    );
  }
}
