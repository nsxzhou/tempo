import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/core/widgets/tempo/tempo.dart';
import 'package:tempo/features/tasks/presentation/widgets/create_action_fan_fab.dart';

void main() {
  testWidgets('expands fan actions and invokes callbacks', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var textTapped = false;
    var voiceTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: TempoThemePresets.minimalWhite.toThemeData(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CreateActionFanFab(
                onTextCreate: () => textTapped = true,
                onVoiceInput: () => voiceTapped = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('文字创建'), findsNothing);
    expect(find.text('语音输入'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('文字创建'), findsOneWidget);
    expect(find.text('语音输入'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fan_action_voice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(voiceTapped, isTrue);
    expect(textTapped, isFalse);

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const Key('fan_action_text')));
    await tester.pump();

    expect(textTapped, isTrue);
  });
}
