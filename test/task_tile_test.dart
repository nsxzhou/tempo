import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/core/theme/app_theme.dart';
import 'package:tempo/core/theme/theme_presets.dart';
import 'package:tempo/features/tasks/domain/task.dart';
import 'package:tempo/features/tasks/presentation/widgets/task_tile.dart';

Task _task({
  String title = '牛奶',
  String? description,
  DateTime? dueDate,
  bool isAllDay = false,
  TaskPriority priority = TaskPriority.none,
  String? tag,
  bool isCompleted = false,
}) {
  final now = DateTime(2026, 6, 19, 10);
  return Task(
    id: 't1',
    listId: 'inbox',
    title: title,
    description: description,
    dueDate: dueDate,
    isAllDay: isAllDay,
    priority: priority,
    tag: tag,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );
}

String _writeTinyPng() {
  final dir = Directory.systemTemp.createTempSync('tempo_task_tile_bg_');
  final file = File('${dir.path}/bg.png');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  file.writeAsBytesSync(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);
  return file.path;
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) {
    final tokens = TempoThemePresets.minimalWhite;
    return ProviderScope(
      child: MaterialApp(
        theme: tokens.toThemeData(),
        home: Scaffold(
          body: SlidableAutoCloseBehavior(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('compact layout: title only, no meta', (tester) async {
    await tester.pumpWidget(
      wrap(
        TaskTile(
          task: _task(description: '全脂牛奶', priority: TaskPriority.p1),
        ),
      ),
    );

    expect(find.text('牛奶'), findsOneWidget);
    expect(find.text('全脂牛奶'), findsNothing);
    expect(find.text('P1'), findsNothing);
    expect(find.text('@工作'), findsNothing);
    expect(find.text('@生活'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('shows category label on the right', (tester) async {
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(tag: AppConstants.tagLife))),
    );

    expect(find.text('@生活'), findsOneWidget);
  });

  testWidgets('tap on title area triggers onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(), onTap: () => tapped = true)),
    );

    await tester.tap(find.text('牛奶'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tap on checkbox toggles without triggering onTap', (
    tester,
  ) async {
    var tapped = false;
    var toggled = false;
    await tester.pumpWidget(
      wrap(
        TaskTile(
          task: _task(),
          onTap: () => tapped = true,
          onToggleComplete: () => toggled = true,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('未完成'));
    await tester.pump();
    await tester.pump(AppTheme.durationFast);
    await tester.pump(AppTheme.durationMedium);

    expect(toggled, isTrue);
    expect(tapped, isFalse);
  });

  testWidgets('swipe left reveals delete action', (tester) async {
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(), showDelete: true, onDelete: () {})),
    );

    expect(find.bySemanticsLabel('删除'), findsNothing);

    await tester.drag(find.byType(Slidable), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('删除'), findsOneWidget);
  });

  testWidgets('delete action calls onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      wrap(
        TaskTile(
          task: _task(),
          showDelete: true,
          onDelete: () => deleted = true,
        ),
      ),
    );

    await tester.drag(find.byType(Slidable), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('删除'));
    await tester.pump();
    await tester.pump(AppTheme.durationFast);

    expect(deleted, isTrue);
  });

  testWidgets('no slidable when showDelete is false', (tester) async {
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(), onDelete: () {}, showDelete: false)),
    );

    expect(find.byType(Slidable), findsNothing);
  });

  testWidgets('task background image does not create BackdropFilter', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(), backgroundImagePath: _writeTinyPng())),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('completed task keeps weakened background image layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        TaskTile(
          task: _task(isCompleted: true),
          backgroundImagePath: _writeTinyPng(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('牛奶'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
