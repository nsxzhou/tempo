import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 待办卡片/封面条背景图。
///
/// 短条 [BoxFit.cover] 区域对横图会按高度裁切，因此解码宽度需按
/// 「视口高 × 最大横图比例」留足余量，避免宽图被过度缩小后再放大发糊。
class TaskBackgroundImage extends StatelessWidget {
  static const double _dprScale = 1.5;
  static const double _maxLandscapeAspect = 12;
  static const int _maxCacheWidth = 3200;

  final String path;
  final Color errorColor;

  const TaskBackgroundImage({
    super.key,
    required this.path,
    required this.errorColor,
  });

  @visibleForTesting
  static int decodeWidthForCover({
    required double layoutWidth,
    required double layoutHeight,
    required double devicePixelRatio,
  }) {
    final physicalWidth = layoutWidth * devicePixelRatio;
    final physicalHeight = layoutHeight * devicePixelRatio;
    final widthForViewport = physicalWidth * _dprScale;
    final widthForWideCover = physicalHeight * _maxLandscapeAspect * _dprScale;
    return math
        .max(widthForViewport, widthForWideCover)
        .round()
        .clamp(1, _maxCacheWidth);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final layoutWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final layoutHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : layoutWidth / 6;

        final cacheWidth = decodeWidthForCover(
          layoutWidth: layoutWidth,
          layoutHeight: layoutHeight,
          devicePixelRatio: dpr,
        );

        return Image.file(
          File(path),
          fit: BoxFit.cover,
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          filterQuality: FilterQuality.none,
          isAntiAlias: true,
          errorBuilder: (_, _, _) => ColoredBox(color: errorColor),
        );
      },
    );
  }
}
