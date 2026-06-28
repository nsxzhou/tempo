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
import 'package:tempo/database/database.dart' hide Task;
import 'package:tempo/app_providers.dart';
import 'package:tempo/core/router/app_router.dart';
import 'package:tempo/features/tasks/data/notification_service.dart';
import 'package:tempo/features/tasks/data/voice_task_parse_result.dart';
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

  testWidgets('low confidence voice parse opens editable draft', (
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.tasks, isEmpty);
    expect(find.text('确认语音任务'), findsOneWidget);

    await tester.tap(find.text('创建'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.single.title, '提交设计稿');
    await tester.pump(const Duration(seconds: 3));
    await repository.dispose();
    await session.dispose();
  });

  testWidgets('backend error does not create a task', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.tasks, isEmpty);
    expect(find.textContaining('创建失败'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await repository.dispose();
    await session.dispose();
  });

  testWidgets('list delete removes task and supports undo', (tester) async {
    final repository = FakeTaskRepository();
    final session = FakeStreamingVoiceSession();
    final parseService = FakeTextParseService();

    tester.view.physicalSize = const Size(800, 1200);
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

  testWidgets(
    'task page has no category filter and keeps all pending visible',
    (tester) async {
      final repository = FakeTaskRepository();
      await repository.createTask(title: '海底捞', tag: AppConstants.tagLife);
      await repository.createTask(title: '去吃KFC');

      tester.view.physicalSize = const Size(800, 1200);
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

    tester.view.physicalSize = const Size(800, 1200);
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

    tester.view.physicalSize = const Size(800, 1200);
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
}

Future<void> _settleAnimations(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> _pumpTasksPage(
  WidgetTester tester, {
  required FakeTaskRepository repository,
  required FakeStreamingVoiceSession session,
  required FakeTextParseService parseService,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        streamingVoiceSessionProvider.overrideWithValue(session),
        textParseServiceProvider.overrideWithValue(parseService),
        notificationServiceProvider.overrideWithValue(
          _NoopNotificationService(),
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

Future<void> _submitVoice(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('voice-fab')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byKey(const ValueKey('voice-mic')));
  await tester.pump();
  await tester.pump();
  expect(find.textContaining('语音采音中'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('voice-mic')));
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
