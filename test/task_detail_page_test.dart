import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tempo/app_providers.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/core/providers/database_provider.dart';
import 'package:tempo/core/router/app_router.dart';
import 'package:tempo/database/database.dart' hide Task, TaskBackground;
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/core/widgets/tempo/src/tempo_background.dart';
import 'package:tempo/features/tasks/data/task_background_repository.dart';
import 'package:tempo/features/tasks/presentation/task_detail_page.dart';

import 'test_fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  testWidgets('detail page edit opens sheet and saves updates', (tester) async {
    final repository = FakeTaskRepository();
    final parseService = FakeTextParseService();
    final task = await repository.createTask(
      title: '去吃KFC',
      dueDate: DateTime(2026, 6, 18, 17),
      priority: TaskPriority.p1,
      tag: AppConstants.tagLife,
    );

    await _pumpDetailPage(
      tester,
      repository: repository,
      parseService: parseService,
      task: task,
    );

    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();

    expect(find.text('保存'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '改吃麦当劳');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repository.tasks.single.title, '改吃麦当劳');
    expect(find.text('改吃麦当劳'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await repository.dispose();
  });

  testWidgets('detail page does not add a second TempoBackground', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final task = await repository.createTask(title: '单层背景');

    await _pumpDetailPage(tester, repository: repository, task: task);

    expect(find.byType(TempoBackground), findsNothing);
    await repository.dispose();
  });

  testWidgets('detail page menu exposes background actions', (tester) async {
    final repository = FakeTaskRepository();
    final task = await repository.createTask(title: '带背景任务');
    final background = TaskBackground(
      taskId: task.id,
      imagePath: '/tmp/test-bg.jpg',
      createdAt: DateTime(2026, 6, 28),
      updatedAt: DateTime(2026, 6, 28),
    );

    await _pumpDetailPage(
      tester,
      repository: repository,
      task: task,
      background: background,
    );

    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();

    expect(find.text('更换背景'), findsOneWidget);
    expect(find.text('清除背景'), findsOneWidget);
    await repository.dispose();
  });

  testWidgets('detail page renders cover strip when task has background', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final task = await repository.createTask(title: '封面标题');
    final background = TaskBackground(
      taskId: task.id,
      imagePath: '/tmp/cover-strip.jpg',
      createdAt: DateTime(2026, 6, 28),
      updatedAt: DateTime(2026, 6, 28),
    );

    await _pumpDetailPage(
      tester,
      repository: repository,
      task: task,
      background: background,
    );

    expect(find.text('封面标题'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await repository.dispose();
  });

  testWidgets('detail page delete confirms and removes task', (tester) async {
    final repository = FakeTaskRepository();
    final task = await repository.createTask(title: '临时任务');

    await _pumpDetailPage(tester, repository: repository, task: task);

    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除待办'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    expect(repository.tasks, isEmpty);
    expect(repository.deletedTaskIds, ['task-0']);
    await repository.dispose();
  });
}

Future<void> _pumpDetailPage(
  WidgetTester tester, {
  required FakeTaskRepository repository,
  required Task task,
  FakeTextParseService? parseService,
  TaskBackground? background,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  final navigatorKey = GlobalKey<NavigatorState>();
  final backgroundRepository = _ConfigurableTaskBackgroundRepository(
    background: background,
  );
  final overrides = <Override>[
    taskRepositoryProvider.overrideWithValue(repository),
    databaseProvider.overrideWithValue(db),
    notificationServiceProvider.overrideWithValue(_NoopNotificationService()),
    appNavigatorKeyProvider.overrideWithValue(navigatorKey),
    taskBackgroundRepositoryProvider.overrideWithValue(backgroundRepository),
    taskBackgroundByTaskIdProvider.overrideWith(
      (ref, taskId) => Stream.value(
        taskId == task.id ? background : null,
      ),
    ),
  ];
  if (parseService != null) {
    overrides.add(textParseServiceProvider.overrideWithValue(parseService));
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: TaskDetailPage(taskId: task.id),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

class _ConfigurableTaskBackgroundRepository implements TaskBackgroundRepository {
  _ConfigurableTaskBackgroundRepository({this.background});

  TaskBackground? background;

  @override
  Future<void> clearBackground(String taskId) async {
    background = null;
  }

  @override
  Future<TaskBackground?> getBackground(String taskId) async =>
      background?.taskId == taskId ? background : null;

  @override
  Future<TaskBackground?> pickBackgroundImage(String taskId) async => null;

  @override
  Future<TaskBackground> setBackgroundFromFile({
    required String taskId,
    required String sourcePath,
  }) {
    throw UnsupportedError('not used in widget tests');
  }

  @override
  Stream<TaskBackground?> watchBackground(String taskId) =>
      Stream.value(background?.taskId == taskId ? background : null);

  @override
  Stream<List<TaskBackground>> watchBackgrounds() =>
      Stream.value(background == null ? const [] : [background!]);
}

class _NoopNotificationService implements NotificationService {
  @override
  void Function(String taskId)? onNotificationTap;

  @override
  Future<void> cancelTaskReminders(String taskId) async {}

  @override
  Future<void> scheduleTaskReminder(Task task) async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> isRemindersEnabled() async => true;

  @override
  Future<void> setRemindersEnabled(bool enabled) async {}

  @override
  Future<void> rescheduleAllTasks(Iterable<Task> tasks) async {}
}
