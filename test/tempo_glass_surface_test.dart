import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/core/theme/theme_manager.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/core/widgets/tempo/tempo.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'TempoGlassSurface has no BackdropFilter without custom background',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: TempoThemePresets.minimalWhite.toThemeData(),
            home: const Scaffold(
              body: TempoGlassSurface(
                child: SizedBox(height: 40, width: double.infinity),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);
    },
  );

  testWidgets(
    'TempoGlassSurface uses BackdropFilter when glass style enabled',
    (tester) async {
      final tokens = TempoThemePresets.minimalWhite;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            glassSurfaceStyleProvider.overrideWith(
              (ref) => GlassSurfaceStyle(
                enabled: true,
                blurSigma: 16,
                fillColor: tokens.bg.withValues(alpha: 0.58),
                borderColor: tokens.borderStrong.withValues(alpha: 0.45),
                solidColor: tokens.bg,
              ),
            ),
          ],
          child: MaterialApp(
            theme: tokens.toThemeData(),
            home: const Scaffold(
              body: TempoGlassSurface(
                blur: true,
                child: SizedBox(height: 40, width: double.infinity),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BackdropFilter), findsOneWidget);
    },
  );

  testWidgets('TempoGlassSurface skips BackdropFilter when blur is false', (
    tester,
  ) async {
    final tokens = TempoThemePresets.minimalWhite;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glassSurfaceStyleProvider.overrideWith(
            (ref) => GlassSurfaceStyle(
              enabled: true,
              blurSigma: 16,
              fillColor: tokens.bg.withValues(alpha: 0.58),
              borderColor: tokens.borderStrong.withValues(alpha: 0.45),
              solidColor: tokens.bg,
            ),
          ),
        ],
        child: MaterialApp(
          theme: tokens.toThemeData(),
          home: const Scaffold(
            body: TempoGlassSurface(
              blur: false,
              child: SizedBox(height: 40, width: double.infinity),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BackdropFilter), findsNothing);
  });
}
