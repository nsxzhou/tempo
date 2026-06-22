import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
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
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );
  }

  testWidgets('compact layout: title only, no extra meta spacing', (tester) async {
    await tester.pumpWidget(wrap(TaskTile(task: _task())));

    expect(find.text('牛奶'), findsOneWidget);
    expect(find.text('@工作'), findsNothing);
    expect(find.text('@生活'), findsNothing);
  });

  testWidgets('withMeta layout: shows priority pill', (tester) async {
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(priority: TaskPriority.p1))),
    );

    expect(find.text('P1'), findsOneWidget);
  });

  testWidgets('withDescription layout: shows description summary', (tester) async {
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(description: '全脂牛奶，超市购买'))),
    );

    expect(find.text('全脂牛奶，超市购买'), findsOneWidget);
  });

  testWidgets('shows tag pill for life category', (tester) async {
    await tester.pumpWidget(
      wrap(TaskTile(task: _task(tag: AppConstants.tagLife))),
    );

    expect(find.text('@生活'), findsOneWidget);
  });

  testWidgets('all-day task shows date without time', (tester) async {
    await tester.pumpWidget(
      wrap(TaskTile(
        task: _task(
          dueDate: DateTime(2026, 6, 25),
          isAllDay: true,
        ),
      )),
    );

    expect(find.text('6月25日'), findsOneWidget);
    expect(find.textContaining(':'), findsNothing);
  });

  testWidgets('tap on chevron triggers onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(TaskTile(
        task: _task(),
        onTap: () => tapped = true,
      )),
    );

    await tester.tap(find.byIcon(LucideIcons.chevron_right));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
