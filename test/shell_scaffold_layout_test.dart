import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/core/theme/app_theme.dart';
import 'package:tempo/core/widgets/tempo/tempo.dart';

Future<void> pumpTabBarStack(WidgetTester tester, Widget tabBarLayer) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.white)),
            tabBarLayer,
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double tabLabelGlobalDy(WidgetTester tester) {
  final box = tester.renderObject(find.text('待办')) as RenderBox;
  return box.localToGlobal(Offset.zero).dy;
}

void main() {
  testWidgets('TempoTabBar anchored at bottom via Stack Positioned', (tester) async {
    await pumpTabBarStack(
      tester,
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: TempoTabBar(currentPath: AppConstants.routeTasks),
      ),
    );

    final dy = tabLabelGlobalDy(tester);
    final screenH = tester.view.physicalSize.height;
    expect(dy, greaterThan(screenH * 0.5), reason: 'tab labels should be near bottom');
  });

  testWidgets('TempoTabBar inside AnimatedSlide without outer Positioned sits at top', (tester) async {
    await pumpTabBarStack(
      tester,
      AnimatedSlide(
        offset: Offset.zero,
        duration: AppTheme.durationFast,
        child: TempoTabBar(currentPath: AppConstants.routeTasks),
      ),
    );

    final dy = tabLabelGlobalDy(tester);
    expect(dy, lessThan(120), reason: 'broken layout parks tabs at top');
  });
}
