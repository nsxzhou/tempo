import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/presentation/widgets/task_background_image.dart';

void main() {
  group('TaskBackgroundImage.decodeWidthForCover', () {
    test('boosts decode width for standard list tile cover crops', () {
      final width = TaskBackgroundImage.decodeWidthForCover(
        layoutWidth: 350,
        layoutHeight: 52,
        devicePixelRatio: 3,
      );
      expect(width, (52 * 3 * 12 * 1.5).round());
    });

    test('uses viewport width when tile is extremely wide', () {
      final width = TaskBackgroundImage.decodeWidthForCover(
        layoutWidth: 400,
        layoutHeight: 20,
        devicePixelRatio: 3,
      );
      expect(width, (400 * 3 * 1.5).round());
    });

    test('clamps to max cache width', () {
      final width = TaskBackgroundImage.decodeWidthForCover(
        layoutWidth: 400,
        layoutHeight: 200,
        devicePixelRatio: 4,
      );
      expect(width, 3200);
    });
  });
}
