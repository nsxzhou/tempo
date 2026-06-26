import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/core/widgets/tempo/src/tempo_background.dart';

void main() {
  test('TempoBackgroundImageCache reuses provider for same file and size', () {
    final cache = TempoBackgroundImageCache();

    final first = cache.providerFor(
      path: '/tmp/background.jpg',
      cacheWidth: 1080,
      cacheHeight: 2400,
    );
    final second = cache.providerFor(
      path: '/tmp/background.jpg',
      cacheWidth: 1080,
      cacheHeight: 2400,
    );

    expect(identical(first, second), isTrue);
  });

  test('TempoBackgroundImageCache refreshes provider when size changes', () {
    final cache = TempoBackgroundImageCache();

    final first = cache.providerFor(
      path: '/tmp/background.jpg',
      cacheWidth: 1080,
      cacheHeight: 2400,
    );
    final second = cache.providerFor(
      path: '/tmp/background.jpg',
      cacheWidth: 1170,
      cacheHeight: 2532,
    );

    expect(identical(first, second), isFalse);
  });

  testWidgets('TempoBackground readability overlay uses vertical gradient', (
    tester,
  ) async {
    final tokens = TempoThemePresets.minimalWhite.copyWith(
      backgroundOverlayOpacity: 0.18,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: tokens.toThemeData(),
        home: Stack(children: [buildTempoBackgroundReadabilityOverlay(tokens)]),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decorated.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;

    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.stops, const [0, 0.28, 0.66, 1]);
    expect(gradient.colors.first, tokens.bg.withValues(alpha: 0.30));
    expect(gradient.colors.last, tokens.bg.withValues(alpha: 0.34));
  });
}
