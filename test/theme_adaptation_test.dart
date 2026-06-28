import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/core/theme/app_theme.dart';
import 'package:tempo/core/theme/tempo_theme_extension.dart';
import 'package:tempo/core/theme/theme_manager.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/core/widgets/tempo/tempo.dart';
import 'package:tempo/features/calendar/presentation/calendar_page.dart';
import 'package:tempo/features/settings/presentation/settings_page.dart';
import 'package:tempo/features/settings/presentation/widgets/theme_settings_section.dart';

Widget wrapWithTheme(Widget child, TempoTokens tokens) {
  return ProviderScope(
    child: MaterialApp(
      theme: tokens.toThemeData(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final preset in TempoThemeId.values) {
    testWidgets(
      'ThemeSettingsSection renders without overflow (${preset.label})',
      (tester) async {
        final tokens = TempoThemePresets.tokensFor(preset);

        await tester.pumpWidget(
          wrapWithTheme(
            const SingleChildScrollView(child: ThemeSettingsSection()),
            tokens,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(preset.label), findsOneWidget);
      },
    );

    testWidgets(
      'Settings integration group uses preset surface (${preset.label})',
      (tester) async {
        final tokens = TempoThemePresets.tokensFor(preset);

        await tester.pumpWidget(
          wrapWithTheme(
            TempoSettingsGroup(
              borderColor: tokens.borderStrong,
              children: const [SizedBox(height: 40, width: double.infinity)],
            ),
            tokens,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(TempoGlassSurface), findsOneWidget);

        if (preset != TempoThemeId.minimalWhite) {
          expect(tokens.bg, isNot(AppTheme.bg));
        }
      },
    );
  }

  testWidgets('CalendarPage renders under deepSpace preset', (tester) async {
    final tokens = TempoThemePresets.deepSpace;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: tokens.toThemeData(),
          home: const CalendarPage(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('日历'), findsOneWidget);
  });

  testWidgets('SettingsPage renders under starry preset', (tester) async {
    final tokens = TempoThemePresets.starry;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: tokens.toThemeData(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('我的'), findsOneWidget);
  });

  test(
    'toThemeData uses transparent scaffold when custom background overlay active',
    () {
      final tokens = TempoThemePresets.minimalWhite.copyWith(
        backgroundOverlayOpacity: 0.18,
      );
      expect(tokens.toThemeData().scaffoldBackgroundColor, Colors.transparent);
    },
  );

  test(
    'active tokens increase card readability with custom background',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'tempo_theme_bg_test_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final bgFile = File('${tempDir.path}/background.jpg');
      await bgFile.writeAsBytes([0]);
      SharedPreferences.setMockInitialValues({
        AppConstants.prefBackgroundImagePath: bgFile.path,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 5; i++) {
        if (container.read(themeManagerProvider).backgroundImageValid) break;
        await Future<void>.delayed(Duration.zero);
      }

      expect(container.read(themeManagerProvider).backgroundImageValid, isTrue);
      final tokens = container.read(activeTempoTokensProvider);
      expect(tokens.backgroundOverlayOpacity, 0.08);
      expect(
        tokens.taskCardBackground,
        TempoThemePresets.minimalWhite.bg.withValues(alpha: 0.78),
      );
    },
  );
}
