import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/app_providers.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/database/database.dart' hide Task;
import 'package:tempo/features/stats/data/stats_repository.dart';
import 'package:tempo/features/stats/domain/stats_models.dart';
import 'package:tempo/features/stats/presentation/stats_page.dart';
import 'package:tempo/features/tasks/domain/task.dart';

class _FakeStatsRepository extends StatsRepository {
  _FakeStatsRepository()
    : super(AppDatabase.forTesting(NativeDatabase.memory()));

  @override
  Stream<List<DailyCompletion>> watchDailyCompletions(int days) {
    return Stream.value(
      List.generate(
        days,
        (i) => DailyCompletion(
          date: DateTime.now().subtract(Duration(days: days - 1 - i)),
          count: 0,
        ),
      ),
    );
  }
}

void main() {
  testWidgets('StatsPage shows period toggle and empty trend state', (
    tester,
  ) async {
    final tokens = TempoThemePresets.minimalWhite;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsRepositoryProvider.overrideWith((ref) => _FakeStatsRepository()),
          taskListProvider.overrideWith((ref) => Stream.value(const <Task>[])),
        ],
        child: MaterialApp(
          theme: tokens.toThemeData(),
          home: const StatsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('统计'), findsOneWidget);
    expect(find.text('暂无完成记录'), findsOneWidget);
    expect(find.text('7 天'), findsOneWidget);
    expect(find.text('30 天'), findsOneWidget);

    await tester.tap(find.text('30 天'));
    await tester.pumpAndSettle();

    expect(find.text('近 30 天'), findsNWidgets(2));
  });
}
