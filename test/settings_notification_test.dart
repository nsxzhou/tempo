import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/app_providers.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/features/settings/data/siyuan_pairing_service.dart';
import 'package:tempo/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('settings page no longer exposes reminder switch', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siyuanBindingStatusProvider.overrideWith(
            (ref) async => const SiyuanBindingStatus(isPaired: false),
          ),
        ],
        child: MaterialApp(
          theme: TempoThemePresets.minimalWhite.toThemeData(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('待办提醒'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });
}
