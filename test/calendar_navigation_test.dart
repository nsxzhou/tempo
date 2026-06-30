import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/app_providers.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/features/calendar/presentation/calendar_page.dart';
import 'package:tempo/features/calendar/presentation/day_view.dart';
import 'package:tempo/features/calendar/presentation/month_view.dart';
import 'package:tempo/features/tasks/domain/task.dart';

void main() {
  Widget wrap(Widget child) {
    final tokens = TempoThemePresets.minimalWhite;
    return ProviderScope(
      child: MaterialApp(
        theme: tokens.toThemeData(),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('MonthView allows tapping other-month cells', (tester) async {
    DateTime? tapped;
    final selected = DateTime(2026, 6, 15);

    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        MonthView(
          selectedDate: selected,
          taskIndex: const {},
          onSelectDate: (d) => tapped = d,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trailing July 1 when viewing June 2026 (after June 1 in grid order).
    await tester.tap(find.text('1').last);
    await tester.pump();

    expect(tapped, DateTime(2026, 7, 1));
  });

  testWidgets('DayView has no internal chevron navigation', (tester) async {
    await tester.pumpWidget(
      wrap(DayView(selectedDate: DateTime(2026, 6, 30))),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.chevron_left), findsNothing);
    expect(find.byIcon(LucideIcons.chevron_right), findsNothing);
    expect(find.text('SELECTED DAY'), findsOneWidget);
  });

  testWidgets('CalendarPage header chevrons change focus date', (tester) async {
    final tokens = TempoThemePresets.minimalWhite;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskListProvider.overrideWith((ref) => Stream.value(const <Task>[])),
        ],
        child: MaterialApp(
          theme: tokens.toThemeData(),
          home: const CalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarPage)),
    );

    container.read(calendarFocusDateProvider.notifier).state = DateTime(
      2026,
      6,
      15,
    );
    await tester.pumpAndSettle();

    expect(
      container.read(calendarFocusDateProvider),
      DateTime(2026, 6, 15),
    );

    await tester.tap(find.byIcon(LucideIcons.chevron_right));
    await tester.pumpAndSettle();

    final afterNext = container.read(calendarFocusDateProvider);
    expect(afterNext.month, 7);
    expect(afterNext.day, 15);

    await tester.tap(find.byIcon(LucideIcons.chevron_left));
    await tester.pumpAndSettle();

    expect(container.read(calendarFocusDateProvider), DateTime(2026, 6, 15));
  });
}
