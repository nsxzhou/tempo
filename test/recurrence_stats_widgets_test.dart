import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/presentation/widgets/streak_summary_card.dart';
import 'package:tempo/features/tasks/presentation/widgets/recurrence_series_timeline.dart';

void main() {
  testWidgets('StreakSummaryCard shows series progress for capped series', (
    tester,
  ) async {
    const info = StreakInfo(
      current: 2,
      longest: 2,
      completedCount: 2,
      scheduledCount: 2,
      seriesTotal: 5,
      seriesCompleted: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StreakSummaryCard(info: info),
        ),
      ),
    );

    expect(find.text('2/5 次'), findsOneWidget);
    expect(find.text('进度'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
  });

  testWidgets('StreakSummaryCard hides progress for unlimited series', (
    tester,
  ) async {
    const info = StreakInfo(
      current: 1,
      longest: 1,
      completedCount: 1,
      scheduledCount: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StreakSummaryCard(info: info),
        ),
      ),
    );

    expect(find.text('当前连续'), findsOneWidget);
    expect(find.text('最长连续'), findsOneWidget);
    expect(find.text('进度'), findsNothing);
    expect(find.text('完成率'), findsNothing);
  });

  testWidgets('RecurrenceSeriesTimeline renders 5 chips with 3 completed', (
    tester,
  ) async {
    final occurrences = [
      for (var i = 0; i < 5; i++)
        TaskOccurrence(
          seriesTaskId: 'series',
          occurrenceDate: DateTime(2026, 6, 1 + i * 2),
          effectiveDue: DateTime(2026, 6, 1 + i * 2),
          title: '打卡',
          state: i < 3 ? OccurrenceState.completed : OccurrenceState.pending,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurrenceSeriesTimeline(occurrences: occurrences),
        ),
      ),
    );

    expect(find.text('第1次'), findsOneWidget);
    expect(find.text('第5次'), findsOneWidget);
    expect(find.text('已完成 3 / 5 次'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsNWidgets(3));
  });

  testWidgets('RecurrenceSeriesTimeline chip tap invokes callback', (
    tester,
  ) async {
    final occurrences = [
      for (var i = 0; i < 5; i++)
        TaskOccurrence(
          seriesTaskId: 'series',
          occurrenceDate: DateTime(2026, 6, 1 + i * 2),
          effectiveDue: DateTime(2026, 6, 1 + i * 2),
          title: '打卡',
          state: OccurrenceState.pending,
        ),
    ];
    TaskOccurrence? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurrenceSeriesTimeline(
            occurrences: occurrences,
            onTapOccurrence: (occ) => tapped = occ,
          ),
        ),
      ),
    );

    await tester.tap(find.text('第2次'));
    await tester.pump();

    expect(tapped?.occurrenceDate, DateTime(2026, 6, 3));
  });
}
