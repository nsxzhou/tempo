import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/tempo_theme_extension.dart';
import '../../../theme/theme_manager.dart';

/// 全屏背景图 + 半透明遮罩，保证文字可读。
class TempoBackground extends ConsumerStatefulWidget {
  final Widget child;

  const TempoBackground({super.key, required this.child});

  @override
  ConsumerState<TempoBackground> createState() => _TempoBackgroundState();
}

class _TempoBackgroundState extends ConsumerState<TempoBackground> {
  final _imageCache = TempoBackgroundImageCache();

  ImageProvider _resolveImageProvider(String imagePath) {
    final size = MediaQuery.sizeOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (size.width * devicePixelRatio).round();
    final cacheHeight = (size.height * devicePixelRatio).round();
    final provider = _imageCache.providerFor(
      path: imagePath,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(provider, context);
    });

    return provider;
  }

  @override
  Widget build(BuildContext context) {
    final customization = ref.watch(themeManagerProvider);
    final tokens = context.tokens;
    final imagePath = customization.backgroundImagePath;

    if (!customization.backgroundImageValid || imagePath == null) {
      _imageCache.clear();
      return widget.child;
    }

    final imageProvider = _resolveImageProvider(imagePath);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: Image(
              image: imageProvider,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: tokens.bg.withValues(alpha: tokens.backgroundOverlayOpacity),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class TempoBackgroundImageCache {
  ImageProvider? _provider;
  String? _path;
  int? _cacheWidth;
  int? _cacheHeight;

  ImageProvider providerFor({
    required String path,
    required int cacheWidth,
    required int cacheHeight,
  }) {
    if (_provider != null &&
        _path == path &&
        _cacheWidth == cacheWidth &&
        _cacheHeight == cacheHeight) {
      return _provider!;
    }

    final provider = ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      FileImage(File(path)),
    );
    _provider = provider;
    _path = path;
    _cacheWidth = cacheWidth;
    _cacheHeight = cacheHeight;
    return provider;
  }

  void clear() {
    _provider = null;
    _path = null;
    _cacheWidth = null;
    _cacheHeight = null;
  }
}

/// 带 Tempo 背景的 Scaffold 包装器。
class TempoScaffold extends ConsumerWidget {
  final Color? backgroundColor;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const TempoScaffold({
    super.key,
    this.backgroundColor,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final scaffoldBg = tokens.backgroundOverlayOpacity > 0
        ? Colors.transparent
        : tokens.bg;
    return Scaffold(
      backgroundColor: backgroundColor ?? scaffoldBg,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: TempoBackground(child: body),
    );
  }
}
