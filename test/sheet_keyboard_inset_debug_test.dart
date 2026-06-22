import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/features/tasks/presentation/widgets/quick_create_sheet.dart';

const _logPath = '/Users/zhouzirui/Desktop/tempo/.cursor/debug-c0bcb2.log';

void _log(String message, Map<String, dynamic> data, {String hypothesisId = 'H1'}) {
  File(_logPath).writeAsStringSync(
    '${jsonEncode({
      'sessionId': 'c0bcb2',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': 'sheet_keyboard_inset_debug_test.dart',
      'message': message,
      'data': data,
      'hypothesisId': hypothesisId,
      'runId': 'pre-fix',
    })}\n',
    mode: FileMode.append,
    flush: true,
  );
}

double _sumBottomPadding(Element root) {
  var sum = 0.0;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Padding) {
      final padding = widget.padding;
      if (padding is EdgeInsets) {
        sum += padding.bottom;
      } else if (padding is EdgeInsetsDirectional) {
        sum += padding.bottom;
      }
    }
    element.visitChildren(visit);
  }

  visit(root);
  return sum;
}

Future<void> _pumpSheet(WidgetTester tester, {required double keyboardInset}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                key: const Key('tempoSheetAlign'),
                alignment: Alignment.bottomCenter,
                child: Padding(
                  key: const Key('tempoSheetKeyboardPadding'),
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: Material(
                  color: Colors.transparent,
                  child: const QuickCreateSheet(),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    final file = File(_logPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  });

  testWidgets('TempoSheet + QuickCreateSheet stack keyboard insets', (tester) async {
    const keyboardInset = 336.0;
    const screenSize = Size(390, 844);

    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSheet(tester, keyboardInset: keyboardInset);
    await tester.pumpAndSettle();

    final alignElement = tester.element(find.byKey(const Key('tempoSheetAlign')));
    final stackedBottomPadding = _sumBottomPadding(alignElement);

    final containerFinder = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).boxShadow?.isNotEmpty == true,
    );
    expect(containerFinder, findsOneWidget);

    final containerBox = tester.renderObject<RenderBox>(containerFinder);
    final sheetTopY = containerBox.localToGlobal(Offset.zero).dy;
    final sheetHeight = containerBox.size.height;
    final sheetBottomY = sheetTopY + sheetHeight;
    final screenHeight = screenSize.height;
    final keyboardTopY = screenHeight - keyboardInset;
    final gapAboveKeyboard = keyboardTopY - sheetBottomY;

    _log('keyboard inset stacking probe', {
      'keyboardInset': keyboardInset,
      'stackedBottomPadding': stackedBottomPadding,
      'sheetTopY': sheetTopY,
      'sheetHeight': sheetHeight,
      'sheetBottomY': sheetBottomY,
      'keyboardTopY': keyboardTopY,
      'gapAboveKeyboard': gapAboveKeyboard,
      'doublePaddingDetected': stackedBottomPadding >= keyboardInset * 2 - 1,
    }, hypothesisId: 'H1');

    expect(
      stackedBottomPadding,
      lessThan(keyboardInset * 2 - 1),
      reason: 'Keyboard inset should only be applied once (TempoSheet)',
    );
    expect(
      gapAboveKeyboard,
      lessThan(8),
      reason: 'Sheet bottom should sit flush above keyboard',
    );
  });
}
