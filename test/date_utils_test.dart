import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/utils/date_utils.dart';

void main() {
  group('date_utils', () {
    test('isDueOnDate matches midnight due dates on same day', () {
      final due = DateTime(2026, 6, 19);
      final day = DateTime(2026, 6, 19, 15, 30);
      expect(isDueOnDate(due, day), isTrue);
    });

    test('isDueInWeekRange includes today through next 7 days', () {
      final now = DateTime(2026, 6, 19, 15);
      final today = DateTime(2026, 6, 19, 9);
      final inSixDays = DateTime(2026, 6, 24);
      final afterWeek = DateTime(2026, 6, 27);

      expect(isDueInWeekRange(today, now), isTrue);
      expect(isDueInWeekRange(inSixDays, now), isTrue);
      expect(isDueInWeekRange(afterWeek, now), isFalse);
    });

    test('isTaskOverdue treats all-day tasks as due until end of day', () {
      final due = DateTime(2026, 6, 19);
      final morning = DateTime(2026, 6, 19, 9);
      final nextDay = DateTime(2026, 6, 20, 1);

      expect(
        isTaskOverdue(
          dueDate: due,
          isAllDay: true,
          isCompleted: false,
          now: morning,
        ),
        isFalse,
      );
      expect(
        isTaskOverdue(
          dueDate: due,
          isAllDay: true,
          isCompleted: false,
          now: nextDay,
        ),
        isTrue,
      );
    });
  });
}
