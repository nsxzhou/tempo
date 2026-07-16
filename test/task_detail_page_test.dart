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
import 'package:tempo/database/database.dart'
    hide Task, TaskBackground, TaskCompletion;
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/core/widgets/tempo/src/tempo_background.dart';
import 'package:tempo/features/tasks/data/task_background_repository.dart';
import 'package:tempo/features/tasks/presentation/task_detail_page.dart';

import 'test_fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
  });

  testWidgets('recurring detail with occurrenceDate targets that day', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));

    final task = await repository.createTask(
      title: '补录测试',
      dueDate: yesterday.subtract(const Duration(days: 29)),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
    );

    await _pumpDetailPage(
      tester,
      repository: repository,
      task: task,
      occurrenceDate: yesterday,
    );

    await tester.ensureVisible(find.text('标记完成'));
    await tester.tap(find.text('标记完成'));
    await tester.pumpAndSettle();

    expect(repository.occurrenceToggles, hasLength(1));
    expect(repository.occurrenceToggles.single.occurrenceDate, yesterday);
    expect(repository.occurrenceToggles.single.complete, isTrue);
    await repository.dispose();
  });

  testWidgets('capped series timeline chip switches completion target date', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final task = await repository.createTask(
      title: '五次打卡',
      dueDate: DateTime(2026, 6, 1),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY;INTERVAL=2;COUNT=5',
      recurrenceCount: 5,
    );

    await _pumpDetailPage(tester, repository: repository, task: task);

    expect(find.text('第3次'), findsOneWidget);
    await tester.tap(find.text('第3次'));
    await tester.pump();

    await tester.ensureVisible(find.text('标记完成'));
    await tester.tap(find.text('标记完成'));
    await tester.pumpAndSettle();

    expect(repository.occurrenceToggles, hasLength(1));
    expect(
      repository.occurrenceToggles.single.occurrenceDate,
      DateTime(2026, 6, 5),
    );
    await repository.dispose();
  });

  testWidgets(
    'recurring detail shows next occurrence instead of overdue anchor',
    (tester) async {
      final repository = FakeTaskRepository();
      final now = DateTime.now();
      final anchor = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1));

      final task = await repository.createTask(
        title: '死虫式',
        dueDate: anchor,
        isAllDay: true,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      );

      await _pumpDetailPage(tester, repository: repository, task: task);

      expect(find.text('下次'), findsOneWidget);
      expect(find.text('已延误'), findsNothing);
      expect(find.text('${now.month}月${now.day}日'), findsOneWidget);
      await repository.dispose();
    },
  );

  testWidgets('active recurring detail shows end recurrence menu item', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final task = await repository.createTask(
      title: '每日锻炼',
      dueDate: DateTime(2026, 6, 1),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
    );

    await _pumpDetailPage(tester, repository: repository, task: task);

    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();

    expect(find.text('结束重复'), findsOneWidget);
    await repository.dispose();
  });

  testWidgets(
    'ended recurring detail can backfill a selected missed occurrence',
    (tester) async {
      final repository = FakeTaskRepository();
      final now = DateTime.now();
      final yesterday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1));
      final task = await repository.createTask(
        title: '结束后补卡',
        dueDate: yesterday.subtract(const Duration(days: 2)),
        isAllDay: true,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
        recurrenceEnd: yesterday,
      );

      await _pumpDetailPage(
        tester,
        repository: repository,
        task: task,
        occurrenceDate: yesterday,
      );

      await tester.ensureVisible(find.text('标记完成'));
      await tester.tap(find.text('标记完成'));
      await tester.pumpAndSettle();

      expect(repository.occurrenceToggles, hasLength(1));
      expect(repository.occurrenceToggles.single.occurrenceDate, yesterday);
      expect(repository.occurrenceToggles.single.complete, isTrue);
      await repository.dispose();
    },
  );

  testWidgets('ended recurring detail hides complete and end actions', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final now = DateTime.now();
    final task = await repository.createTask(
      title: '已结束习惯',
      dueDate: DateTime(2026, 6, 1),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      recurrenceEnd: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1)),
    );

    await _pumpDetailPage(tester, repository: repository, task: task);

    expect(find.text('标记完成'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();

    expect(find.text('结束重复'), findsNothing);
    await repository.dispose();
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
  DateTime? occurrenceDate,
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
      (ref, taskId) => Stream.value(taskId == task.id ? background : null),
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
        home: TaskDetailPage(taskId: task.id, occurrenceDate: occurrenceDate),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

class _ConfigurableTaskBackgroundRepository
    implements TaskBackgroundRepository {
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

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> cancelTaskReminders(String taskId) async {}

  @override
  Future<void> cancelOccurrenceReminder(
    String taskId,
    DateTime occurrenceDate,
  ) async {}

  @override
  Future<ReminderScheduleResult> scheduleTaskReminder(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async =>
      const ReminderScheduleResult(status: ReminderScheduleStatus.scheduled);

  @override
  Future<ReminderScheduleResult> scheduleRecurringReminders(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async =>
      const ReminderScheduleResult(status: ReminderScheduleStatus.scheduled);

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> rescheduleAllTasks(
    Iterable<Task> tasks, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async =>
      const ReminderScheduleResult(status: ReminderScheduleStatus.scheduled);
}
