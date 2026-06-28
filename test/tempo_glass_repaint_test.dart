import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tempo/app_providers.dart';
import 'package:tempo/core/theme/theme_manager.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/core/widgets/tempo/src/tempo_glass_surface.dart';
import 'package:tempo/core/widgets/tempo/src/tempo_tab_bar.dart';
import 'package:tempo/features/tasks/presentation/tasks_page.dart';

import 'test_fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  testWidgets('TasksPage bento uses single outer TempoGlassSurface', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          taskBackgroundRepositoryProvider.overrideWithValue(
            FakeTaskBackgroundRepository(),
          ),
          taskBackgroundMapProvider.overrideWith((ref) => const {}),
          hasCustomBackgroundProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: TempoThemePresets.minimalWhite.toThemeData(),
          home: const TasksPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final glassSurfaces = tester.widgetList<TempoGlassSurface>(
      find.byType(TempoGlassSurface),
    );
    expect(glassSurfaces.length, lessThan(6));
    expect(find.byType(RepaintBoundary), findsWidgets);
  });

  testWidgets('TabBar glass is wrapped in RepaintBoundary', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hasCustomBackgroundProvider.overrideWithValue(true)],
        child: const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: TempoTabBar(currentPath: '/tasks'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(find.byType(TempoGlassSurface), findsOneWidget);
  });
}
