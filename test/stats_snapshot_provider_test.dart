import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/app_providers.dart';
import 'package:tempo/features/tasks/domain/task.dart';

void main() {
  test(
    'statsSnapshotProvider aggregates from task list in provider layer',
    () async {
      final now = DateTime(2026, 6, 25);
      final tasks = List.generate(
        100,
        (i) => Task(
          id: 't-$i',
          listId: 'inbox',
          title: 'Task $i',
          tag: i.isEven ? 'work' : 'life',
          isCompleted: i % 4 == 0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          taskListProvider.overrideWith((ref) => Stream.value(tasks)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskListProvider.future);
      final snapshot = container.read(statsSnapshotProvider(7));
      expect(snapshot.health.pending, 75);
      expect(snapshot.completionRate.total, 100);
      expect(snapshot.categorySlices, isNotEmpty);
    },
  );

  test('taskMapProvider offers O(1) lookup by id', () async {
    final task = Task(
      id: 'abc',
      listId: 'inbox',
      title: 'Lookup',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final container = ProviderContainer(
      overrides: [
        taskListProvider.overrideWith((ref) => Stream.value([task])),
      ],
    );
    addTearDown(container.dispose);

    await container.read(taskListProvider.future);
    expect(container.read(taskByIdProvider('abc'))?.title, 'Lookup');
    expect(container.read(taskByIdProvider('missing')), isNull);
  });
}
