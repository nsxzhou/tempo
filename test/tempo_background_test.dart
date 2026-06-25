import 'package:flutter_test/flutter_test.dart';
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
}
