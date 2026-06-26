import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/features/settings/presentation/widgets/theme_settings_section.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ThemeSettingsSection shows all presets without overflow', (
    tester,
  ) async {
    final tokens = TempoThemePresets.minimalWhite;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: tokens.toThemeData(),
          home: const Scaffold(
            body: SingleChildScrollView(child: ThemeSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('极简白'), findsOneWidget);
    expect(find.text('深空黑'), findsOneWidget);
    expect(find.text('暖阳'), findsOneWidget);
    expect(find.text('薄荷'), findsOneWidget);
    expect(find.text('星空'), findsOneWidget);
    expect(find.text('THEME · 主题'), findsOneWidget);
    expect(find.text('组件配色'), findsOneWidget);
    expect(find.text('任务卡片背景'), findsOneWidget);
    expect(find.text('顶栏背景'), findsNothing);
  });

  testWidgets('ThemeSettingsSection theme tap updates selection', (
    tester,
  ) async {
    final tokens = TempoThemePresets.minimalWhite;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: tokens.toThemeData(),
          home: const Scaffold(body: ThemeSettingsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('深空黑'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
