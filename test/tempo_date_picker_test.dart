import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/widgets/tempo/src/tempo_date_picker.dart';

void main() {
  group('canNavigateToPreviousMonth', () {
    test(
      'allows navigating back when firstDate is mid-month and display is next month',
      () {
        final firstDate = DateTime(2026, 6, 24);
        final displayMonth = DateTime(2026, 7);

        expect(
          canNavigateToPreviousMonth(
            displayMonth: displayMonth,
            firstDate: firstDate,
          ),
          isTrue,
        );
      },
    );

    test('disallows navigating before firstDate month', () {
      final firstDate = DateTime(2026, 6, 24);
      final displayMonth = DateTime(2026, 6);

      expect(
        canNavigateToPreviousMonth(
          displayMonth: displayMonth,
          firstDate: firstDate,
        ),
        isFalse,
      );
    });

    test('allows navigating when display month is after first month', () {
      final firstDate = DateTime(2026, 6, 1);
      final displayMonth = DateTime(2026, 8);

      expect(
        canNavigateToPreviousMonth(
          displayMonth: displayMonth,
          firstDate: firstDate,
        ),
        isTrue,
      );
    });
  });
}
