import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/app.dart';
import 'package:tempo/app_providers.dart';

import 'test_fakes.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final repository = FakeTaskRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          voiceRecorderProvider.overrideWithValue(FakeVoiceRecorder()),
          voiceTaskServiceProvider.overrideWithValue(FakeVoiceTaskService()),
        ],
        child: const TempoApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Tempo'), findsOneWidget);
    await repository.dispose();
  });
}
