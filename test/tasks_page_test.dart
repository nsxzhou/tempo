import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/core/providers/database_provider.dart';
import 'package:tempo/core/router/shell_scaffold.dart';
import 'package:tempo/core/theme/app_theme.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/core/widgets/tempo/tempo.dart';
import 'package:tempo/database/database.dart' hide Task, TaskCompletion;
import 'package:tempo/app_providers.dart';
import 'package:tempo/core/router/app_router.dart';
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/features/tasks/data/sync_service.dart';
import 'package:tempo/features/tasks/data/task_repository.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
import 'package:tempo/features/tasks/domain/recurrence_models.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/features/tasks/presentation/task_detail_page.dart';
import 'package:tempo/features/tasks/presentation/tasks_page.dart';

import 'test_fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN', null);
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('high confidence voice parse creates task and supports undo', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final session = FakeStreamingVoiceSession();
    final parseService = FakeTextParseService(result: _voiceResult());

    await _pumpTasksPage(
      tester,
      repository: repository,
      session: session,
      parseService: parseService,
    );

    await _submitVoice(tester);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(session.started, isTrue);
    expect(session.stopped, isTrue);
    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.single.title, '提交设计稿');
    expect(repository.tasks.single.creationSource, 'voice');
    expect(find.textContaining('已创建语音任务'), findsOneWidget);

    await tester.tap(find.text('撤回'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.deletedTaskIds, ['task-0']);
    await tester.pump(const Duration(seconds: 3));
    await repository.dispose();
    await session.dispose();
  });

  testWidgets('voice tap end shows processing before parsed task is created', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final session = FakeStreamingVoiceSession();
    final parseService = FakeTextParseService(
      result: _voiceResult(),
      parseDelay: const Duration(milliseconds: 200),
    );

    await _pumpTasksPage(
      tester,
      repository: repository,
      session: session,
      parseService: parseService,
    );

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const Key('fan_action_voice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.ensureVisible(find.byKey(const Key('voice_mic_button')));
    await tester.tap(find.byKey(const Key('voice_mic_button')));
    await tester.pump();
    expect(find.text('再次轻触结束'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('voice_mic_button')));
    await tester.tap(find.byKey(const Key('voice_mic_button')));
    await tester.pump();
    expect(repository.tasks, isEmpty);
    expect(find.textContaining('中…'), findsWidgets);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.single.title, '提交设计稿');
    await tester.pump(const Duration(seconds: 3));
    await repository.dispose();
    await session.dispose();
  });

  testWidgets('low confidence voice parse opens draft sheet without creating', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final session = FakeStreamingVoiceSession();
    final parseService = FakeTextParseService(
      result: _voiceResult(confidence: 0.52),
    );

    await _pumpTasksPage(
      tester,
      repository: repository,
      session: session,
      parseService: parseService,
    );

    await _submitVoice(tester);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.tasks, isEmpty);
    expect(find.text('拟定待办…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await repository.dispose();
    await session.dispose();
  });

  testWidgets('parse failure opens draft sheet with raw transcript', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final session = FakeStreamingVoiceSession();
    final parseService = FakeTextParseService();

    await _pumpTasksPage(
      tester,
      repository: repository,
      session: session,
      parseService: parseService,
    );

    await _submitVoice(tester);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.tasks, isEmpty);
    expect(find.textContaining('明天下午三点提交设计稿'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
    await repository.dispose();
    await session.dispose();
  });

  testWidgets('list delete removes task and supports undo', (tester) async {
    final repository = FakeTaskRepository();
    final session = FakeStreamingVoiceSession();
    final parseService = FakeTextParseService();

    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await repository.createTask(title: '面包');
    await _pumpTasksPage(
      tester,
      repository: repository,
      session: session,
      parseService: parseService,
    );

    expect(find.text('面包'), findsOneWidget);
    await tester.drag(find.byType(Slidable), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('删除'));
    await tester.pump();
    await tester.pump(AppTheme.durationFast);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.tasks, isEmpty);
    expect(repository.deletedTaskIds, ['task-0']);
    expect(find.textContaining('已删除:面包'), findsOneWidget);

    await tester.ensureVisible(find.text('撤回'));
    await tester.tap(find.text('撤回'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.single.title, '面包');
    await _settleAnimations(tester);
    await repository.dispose();
    await session.dispose();
  });

  testWidgets('pull to refresh pushes pending before remote refresh', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final session = FakeStreamingVoiceSession();
    final parseService = FakeTextParseService();

    await repository.createTask(title: '刷新目标');
    await _pumpTasksPage(
      tester,
      repository: repository,
      session: session,
      parseService: parseService,
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.pushPendingCalls, 1);
    expect(repository.refreshNowCalls, 1);
    await _settleAnimations(tester);
    await repository.dispose();
    await session.dispose();
  });

  testWidgets(
    'completing recurring task reschedules with adjusted completions',
    (tester) async {
      final repository = FakeTaskRepository();
      final session = FakeStreamingVoiceSession();
      final parseService = FakeTextParseService();
      final notifications = _RecordingNotificationService();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 23);
      final previousDay = today.subtract(const Duration(days: 1));

      await repository.createTask(
        title: '喝水',
        dueDate: today,
        recurrenceRule: 'FREQ=DAILY',
      );

      await _pumpTasksPage(
        tester,
        repository: repository,
        session: session,
        parseService: parseService,
        notificationService: notifications,
        completions: [
          TaskCompletion(
            taskId: 'task-0',
            occurrenceDate: previousDay,
            completedAt: previousDay.add(const Duration(hours: 1)),
          ),
        ],
      );

      expect(find.text('喝水'), findsOneWidget);
      await tester.tap(find.byType(TempoCheckbox).first);
      await tester.pump(AppTheme.durationFast + AppTheme.durationMedium);

      expect(repository.occurrenceToggles.single.complete, isTrue);
      expect(notifications.recurringCalls, hasLength(1));
      final completionDays = notifications.recurringCalls.single.completions
          .map((completion) => completion.calendarDay)
          .toSet();
      expect(
        completionDays,
        contains(
          TaskCompletion(
            taskId: 'task-0',
            occurrenceDate: previousDay,
            completedAt: previousDay,
          ).calendarDay,
        ),
      );
      expect(
        completionDays,
        contains(
          TaskCompletion(
            taskId: 'task-0',
            occurrenceDate: today,
            completedAt: today,
          ).calendarDay,
        ),
      );

      await _settleAnimations(tester);
      await repository.dispose();
      await session.dispose();
    },
  );

  testWidgets(
    'task page has no category filter and keeps all pending visible',
    (tester) async {
      final repository = FakeTaskRepository();
      await repository.createTask(title: '海底捞', tag: AppConstants.tagLife);
      await repository.createTask(title: '去吃KFC');

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(repository),
            streamingVoiceSessionProvider.overrideWithValue(
              FakeStreamingVoiceSession(),
            ),
            textParseServiceProvider.overrideWithValue(FakeTextParseService()),
            notificationServiceProvider.overrideWithValue(
              _NoopNotificationService(),
            ),
            taskBackgroundRepositoryProvider.overrideWithValue(
              FakeTaskBackgroundRepository(),
            ),
            taskBackgroundMapProvider.overrideWith((ref) => const {}),
          ],
          child: MaterialApp(
            theme: TempoThemePresets.minimalWhite.toThemeData(),
            home: const TasksPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('海底捞'), findsOneWidget);
      expect(find.text('去吃KFC'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('工作'), findsNothing);
      expect(find.text('生活'), findsNothing);
      expect(find.text('未分类'), findsNothing);
      await _settleAnimations(tester);
      await repository.dispose();
    },
  );

  testWidgets('all scope shows completed without category filtering', (
    tester,
  ) async {
    final repository = FakeTaskRepository();
    final doneWork = await repository.createTask(
      title: '已完成工作',
      tag: AppConstants.tagWork,
    );
    await repository.toggleComplete(doneWork.id);
    await repository.createTask(title: '活跃生活', tag: AppConstants.tagLife);
    await repository.createTask(title: '未分类任务');

    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          streamingVoiceSessionProvider.overrideWithValue(
            FakeStreamingVoiceSession(),
          ),
          textParseServiceProvider.overrideWithValue(FakeTextParseService()),
          notificationServiceProvider.overrideWithValue(
            _NoopNotificationService(),
          ),
          taskBackgroundRepositoryProvider.overrideWithValue(
            FakeTaskBackgroundRepository(),
          ),
          taskBackgroundMapProvider.overrideWith((ref) => const {}),
        ],
        child: MaterialApp(
          theme: TempoThemePresets.minimalWhite.toThemeData(),
          home: const TasksPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('已完成工作'), findsNothing);
    expect(find.text('活跃生活'), findsOneWidget);
    expect(find.text('未分类任务'), findsOneWidget);

    await tester.tap(find.text('全部'));
    await tester.pump();

    expect(find.text('已完成工作'), findsOneWidget);
    expect(find.text('已完成 · 1'), findsOneWidget);
    await _settleAnimations(tester);
    await repository.dispose();
  });

  testWidgets('task detail route instantly covers task list', (tester) async {
    final repository = FakeTaskRepository();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await repository.createTask(title: '列表不应透出');
    await repository.createTask(title: '详情任务');

    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: AppConstants.routeTasks,
      routes: [
        ShellRoute(
          builder: (context, state, child) => ShellScaffold(child: child),
          routes: [
            GoRoute(
              path: AppConstants.routeTasks,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TasksPage()),
            ),
          ],
        ),
        GoRoute(
          path: AppConstants.routeTaskDetail,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return CustomTransitionPage<void>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) => child,
              child: TaskDetailPage(taskId: id),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          databaseProvider.overrideWithValue(db),
          streamingVoiceSessionProvider.overrideWithValue(
            FakeStreamingVoiceSession(),
          ),
          textParseServiceProvider.overrideWithValue(FakeTextParseService()),
          notificationServiceProvider.overrideWithValue(
            _NoopNotificationService(),
          ),
          taskBackgroundRepositoryProvider.overrideWithValue(
            FakeTaskBackgroundRepository(),
          ),
          taskBackgroundByTaskIdProvider.overrideWith(
            (ref, taskId) => Stream.value(null),
          ),
          taskBackgroundMapProvider.overrideWith((ref) => const {}),
        ],
        child: MaterialApp.router(
          theme: TempoThemePresets.minimalWhite.toThemeData(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(TempoTabBar), findsOneWidget);
    expect(find.text('详情任务'), findsOneWidget);
    expect(find.text('列表不应透出'), findsOneWidget);

    await tester.tap(find.text('详情任务'));
    await tester.pump();

    expect(find.text('列表不应透出'), findsNothing);
    expect(find.byType(TempoTabBar), findsNothing);
    expect(find.text('无附加任务描述。点击可输入备注…'), findsOneWidget);

    await repository.dispose();
  });
  testWidgets('shows notification recovery banner for scheduled tasks', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefNotificationPermissionExplained: true,
    });
    final repository = FakeTaskRepository();
    repository.tasks.add(
      Task(
        id: 'scheduled-task',
        listId: 'inbox',
        title: '两分钟后提醒',
        dueDate: DateTime.now().add(const Duration(minutes: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final notifications = _CapabilityNotificationService(
      const NotificationCapability(
        notificationsAllowed: false,
        exactAlarmsAllowed: true,
      ),
    );

    await _pumpTasksPage(
      tester,
      repository: repository,
      session: FakeStreamingVoiceSession(),
      parseService: FakeTextParseService(),
      notificationService: notifications,
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('notification-permission-banner')),
      findsOneWidget,
    );
    expect(find.textContaining('通知权限或渠道未开启'), findsOneWidget);
    await repository.dispose();
  });

  testWidgets(
    'hides diagnostics banner when capabilities are available with no pending reminders',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefNotificationPermissionExplained: true,
      });
      final repository = FakeTaskRepository();
      repository.tasks.add(
        Task(
          id: 'scheduled-task',
          listId: 'inbox',
          title: '两分钟后提醒',
          dueDate: DateTime.now().add(const Duration(minutes: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await _pumpTasksPage(
        tester,
        repository: repository,
        session: FakeStreamingVoiceSession(),
        parseService: FakeTextParseService(),
        notificationService: _CapabilityNotificationService(
          const NotificationCapability(
            notificationsAllowed: true,
            exactAlarmsAllowed: true,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('notification-permission-banner')),
        findsNothing,
      );
      await repository.dispose();
    },
  );
}

Future<void> _settleAnimations(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> _pumpTasksPage(
  WidgetTester tester, {
  required FakeTaskRepository repository,
  required FakeStreamingVoiceSession session,
  required FakeTextParseService parseService,
  NotificationService? notificationService,
  List<TaskCompletion> completions = const [],
  List<RecurrenceException> exceptions = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding.zero;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        syncServiceProvider.overrideWithValue(
          SyncService(
            repository: repository,
            connectivity: _AlwaysOnlineConnectivity(),
          ),
        ),
        streamingVoiceSessionProvider.overrideWithValue(session),
        textParseServiceProvider.overrideWithValue(parseService),
        notificationServiceProvider.overrideWithValue(
          notificationService ?? _NoopNotificationService(),
        ),
        notificationCapabilityProvider.overrideWith((ref) async {
          return (notificationService ?? _NoopNotificationService())
              .capability();
        }),
        taskCompletionsProvider.overrideWith(
          (ref) => Stream.value(completions),
        ),
        taskRecurrenceExceptionsProvider.overrideWith(
          (ref) => Stream.value(exceptions),
        ),
        appNavigatorKeyProvider.overrideWithValue(navigatorKey),
        taskBackgroundRepositoryProvider.overrideWithValue(
          FakeTaskBackgroundRepository(),
        ),
        taskBackgroundMapProvider.overrideWith((ref) => const {}),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: TempoThemePresets.minimalWhite.toThemeData(),
        home: const TasksPage(),
      ),
    ),
  );
  await tester.pump();
}

class _AlwaysOnlineConnectivity extends ConnectivityService {
  @override
  Future<bool> get isOnline async => true;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => const Stream.empty();
}

Future<void> _submitVoice(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.plus));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));

  await tester.tap(find.byKey(const Key('fan_action_voice')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  expect(find.text('轻触开始录音'), findsOneWidget);

  await tester.ensureVisible(find.byKey(const Key('voice_mic_button')));
  await tester.tap(find.byKey(const Key('voice_mic_button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.text('再次轻触结束'), findsOneWidget);

  await tester.ensureVisible(find.byKey(const Key('voice_mic_button')));
  await tester.tap(find.byKey(const Key('voice_mic_button')));
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

VoiceTaskParseResult _voiceResult({double confidence = 0.86}) {
  return VoiceTaskParseResult(
    title: '提交设计稿',
    description: '识别内容: 明天下午三点提交设计稿，优先级高',
    dueDate: DateTime(2026, 6, 19, 15),
    priority: TaskPriority.p1,
    confidence: confidence,
    rawTranscript: '明天下午三点提交设计稿，优先级高',
  );
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

class _RecordingNotificationService extends _NoopNotificationService {
  final recurringCalls = <({Task task, List<TaskCompletion> completions})>[];

  @override
  Future<ReminderScheduleResult> scheduleRecurringReminders(
    Task task, {
    List<TaskCompletion> completions = const [],
    List<RecurrenceException> exceptions = const [],
  }) async {
    recurringCalls.add((task: task, completions: List.of(completions)));
    return const ReminderScheduleResult(
      status: ReminderScheduleStatus.scheduled,
    );
  }
}

class _CapabilityNotificationService extends _NoopNotificationService {
  _CapabilityNotificationService(this.value);

  final NotificationCapability value;
  bool openedNotificationSettings = false;
  bool openedExactAlarmSettings = false;

  @override
  Future<NotificationCapability> capability() async => value;

  @override
  Future<ReminderDiagnostics> diagnostics() async => ReminderDiagnostics(
    now: DateTime(2026, 7, 15, 12),
    timezoneName: 'Asia/Shanghai',
    capability: value,
    pendingCount: 0,
  );

  @override
  Future<void> openNotificationSettings() async {
    openedNotificationSettings = true;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    openedExactAlarmSettings = true;
  }
}
