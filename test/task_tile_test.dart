import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tempo/core/constants/app_constants.dart';
import 'package:tempo/core/theme/app_theme.dart';
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

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SlidableAutoCloseBehavior(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('compact layout: title only, no meta', (tester) async {
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(description: '全脂牛奶', priority: TaskPriority.p1))),
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
      wrap(TaskTile(
        task: _task(),
        onTap: () => tapped = true,
      )),
    );

    await tester.tap(find.text('牛奶'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tap on checkbox toggles without triggering onTap', (tester) async {
    var tapped = false;
    var toggled = false;
    await tester.pumpWidget(
      wrap(TaskTile(
        task: _task(),
        onTap: () => tapped = true,
        onToggleComplete: () => toggled = true,
      )),
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
      wrap(TaskTile(
        task: _task(),
        showDelete: true,
        onDelete: () {},
      )),
    );

    expect(find.bySemanticsLabel('删除'), findsNothing);

    await tester.drag(find.byType(Slidable), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('删除'), findsOneWidget);
  });

  testWidgets('delete action calls onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      wrap(TaskTile(
        task: _task(),
        showDelete: true,
        onDelete: () => deleted = true,
      )),
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
      wrap(TaskTile(
        task: _task(),
        onDelete: () {},
        showDelete: false,
      )),
    );

    expect(find.byType(Slidable), findsNothing);
  });
}
