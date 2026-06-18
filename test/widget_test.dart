import 'package:flutter_test/flutter_test.dart';

import 'package:tempo/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TempoApp());
    await tester.pumpAndSettle();

    // 验证应用正常启动
    expect(find.text('Tempo'), findsOneWidget);
  });
}
