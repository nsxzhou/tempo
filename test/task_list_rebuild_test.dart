import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tempo/app_providers.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/features/tasks/presentation/tasks_page.dart';

import 'test_fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  testWidgets('task list updates when repository emits new tasks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeTaskRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          streamingVoiceSessionProvider.overrideWithValue(
            FakeStreamingVoiceSession(),
          ),
          textParseServiceProvider.overrideWithValue(FakeTextParseService()),
          taskBackgroundRepositoryProvider.overrideWithValue(
            FakeTaskBackgroundRepository(),
          ),
          taskBackgroundMapProvider.overrideWith((ref) => const {}),
        ],
        child: MaterialApp(
          theme: TempoThemePresets.minimalWhite.toThemeData(),
          home: const TasksPage(),
        ),
      ),
    );
    await tester.pump();

    await repository.createTask(title: 'Alpha');
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);

    await repository.createTask(title: 'Beta');
    await tester.pumpAndSettle();

    expect(find.text('Beta'), findsOneWidget);
  });
}
