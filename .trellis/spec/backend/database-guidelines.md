# Database Guidelines

> Tempo uses Drift over SQLite for local persistence with an optimistic
> local-first sync strategy backed by Supabase. The local database serves the
> interactive UI immediately; Supabase remains the eventual source of truth.

## ORM And Connection

- Use Drift for local database schema and queries.
- `lib/database/database.dart` defines `AppDatabase` with
  `@DriftDatabase(tables: [TaskLists, Tasks])`.
- `AppDatabase()` must open SQLite through `_openConnection()`, which stores
  `tempo.sqlite` in `getApplicationDocumentsDirectory()`.
- Expose the database through `databaseProvider` in
  `lib/core/providers/database_provider.dart`; close it with `ref.onDispose`.

## Table Patterns

- Define all Drift tables in `lib/database/tables.dart`.
- Use text primary keys for synced entities:

```dart
TextColumn get id => text()();

@override
Set<Column> get primaryKey => {id};
```

- Use Drift defaults for local defaults:

```dart
IntColumn get sortOrder => integer().withDefault(const Constant(0))();
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
```

- Model relationships with Drift references. Current example:

```dart
TextColumn get listId => text().references(TaskLists, #id)();
```

## Query Patterns

- Keep raw Drift query code in the data/database layer. Current example:
  `AppDatabase.allTasks()` calls `select(tasks).get()` and maps rows with
  `toJson()`.
- UI should consume Riverpod providers, not Drift tables directly.
- Feature repositories live in `lib/features/<feature>/data/` and return
  domain models from `lib/features/<feature>/domain/`. The `tasks` feature
  demonstrates the full pattern with `TaskRepository` interface +
  `SyncTaskRepository` implementation.
- Prefer typed Drift rows or domain models over untyped `Map<String, dynamic>`
  for new feature work. The current `allTasks()` map return is an early
  bootstrap bridge, not a pattern to expand.

## Schema

- Current schema version: **8** (adds `syncPending`, `tag`, `isAllDay`, task
  query indexes, local backgrounds, recurrence tables, and task delete outbox
  across migrations).
- Synced local tables include a `syncPending` column (boolean, default false
  except delete outbox) that tracks whether a local write has been pushed to
  Supabase yet.

## Optimistic Local-First Sync Architecture

### Design Decision: Optimistic Local-First Writes

**Context**: Tasks must survive device loss and sync across devices. Pure
CRDT/automerge is overkill for a single-user task app, but mobile interactions
must not wait for network round trips.

**Decision**: Drift accepts writes immediately for UI responsiveness. Supabase
is reconciled in the background and remains the eventual authority.

**Write path** (`SyncTaskRepository.createTask` / `updateTask` / `toggleComplete` / `deleteTask`):

1. Create/update/toggle writes to Drift first so providers emit immediately.
2. Signed-in task writes set `syncPending = true` and launch a background
   Supabase upsert.
3. Successful remote upsert writes the confirmed row back to Drift with
   `syncPending = false`.
4. Failed or offline remote sync leaves `syncPending = true`; `SyncService`
   retries pending records when connectivity returns.
5. Delete is local-first: remove the Drift task row immediately, insert a
   `TaskDeletionOutbox` tombstone for signed-in users, and clear the tombstone
   only after Supabase delete succeeds.

**Read path** (local-first + background refresh):

1. `watchTasks()` returns a Drift `Stream<List<Task>>` immediately (millisecond
   response).
2. In the background, fetch latest from Supabase and silently upsert into Drift.
3. The Drift stream automatically re-emits with the updated data.

### Sync Engine (`SyncService`)

- Listens to `ConnectivityService.onConnectivityChanged`.
- On network restore, calls `repository.pushPending()` which finds all
  `syncPending == true` rows and pushes them to Supabase, including queued
  deletes from `TaskDeletionOutbox`.
- On app startup, pushes any accumulated pending records immediately.
- Guards against concurrent sync with an `_isSyncing` flag.

## Scenario: Task Delete Outbox

### 1. Scope / Trigger
- Trigger: changing local-first delete behavior for tasks or adding a new task
  sync queue/tombstone table.

### 2. Signatures
- Drift table: `TaskDeletionOutbox(taskId TEXT PRIMARY KEY, deletedAt
  DateTime, syncPending bool default true)`.
- Repository APIs: `TaskRepository.deleteTask(id)`,
  `TaskRepository.pushPending()`, `TaskRepository.refreshNow()`.

### 3. Contracts
- Signed-in deletes insert a tombstone before removing the local `Tasks` row.
- Unauthenticated local deletes do not insert tombstones because no Supabase
  user context exists.
- Remote refresh must skip any task id present in pending delete tombstones.

### 4. Validation & Error Matrix
- Offline delete -> local row removed, tombstone retained, remote delete
  retried by `pushPending()`.
- Supabase delete failure -> tombstone retained; task stays absent locally.
- Supabase delete success -> tombstone removed.

### 5. Good/Base/Bad Cases
- Good: deleted task stays hidden during offline refresh and later remote delete
  clears the tombstone.
- Base: online delete clears the tombstone immediately after remote success.
- Bad: remote refresh re-inserts a task id that is waiting in the delete
  outbox.

### 6. Tests Required
- Repository test: refresh with a stale remote row does not resurrect a pending
  delete.
- Repository test: reconnecting `pushPending()` sends queued delete once and
  clears the queue.
- Migration test: v6/v7 databases migrate to current schema and can insert into
  `task_deletion_outbox`.

### 7. Wrong vs Correct

#### Wrong
```dart
await localDb.tasks.deleteWhere((task) => task.id.equals(id));
unawaited(supabase.from('tasks').delete().eq('id', id));
```

#### Correct
```dart
await localDb.taskDeletionOutbox.insertOnConflictUpdate(tombstone);
await localDb.tasks.deleteWhere((task) => task.id.equals(id));
```

### Connectivity Service (`ConnectivityService`)

- Wraps `connectivity_plus` (5.x API: `onConnectivityChanged` emits
  `List<ConnectivityResult>` for multi-NIC).
- `isOnline` getter: non-`none` result means online.
- `dispose()` is a no-op; the stream lifecycle is managed by the plugin.

### Provider Wiring (in `app_providers.dart`)

```dart
taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return SyncTaskRepository(
    localDb: ref.watch(databaseProvider),
    supabase: ref.watch(supabaseProvider),
    userId: ref.watch(currentUserIdProvider),
    listId: ref.watch(defaultListIdProvider).valueOrNull ?? 'local-inbox',
    connectivity: ref.watch(connectivityProvider),
  );
});

taskListProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTasks();
});

syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    repository: ref.watch(taskRepositoryProvider),
    connectivity: ref.watch(connectivityProvider),
  );
});
```

## Migrations

- Increment `schemaVersion` whenever tables or columns change.
- Add migration logic in `MigrationStrategy.onUpgrade`; do not rely on
  destructive resets.
- Keep `onCreate` as `await m.createAll()` for initial installs.
- After table or database changes, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## Generated Files

- Commit generated Drift files required by `part` directives.
- Do not manually edit `database.g.dart`. Change `tables.dart` or
  `database.dart`, then regenerate.

## Common Mistakes

- Forgetting to commit generated files after changing Drift or Freezed sources.
- Adding query logic to widgets instead of providers/repositories.
- Bumping schema structure without bumping `schemaVersion`.
- Creating additional `AppDatabase()` instances outside the provider lifecycle.

## Local Reminder Ownership

Tempo reminders are device-local and must not depend on task sync success,
Firebase, an Edge Function, or a server Cron.

- Every incomplete local task with a due date is owned by
  `NotificationService` on that device.
- Single tasks schedule one stable notification keyed by `taskId`.
- Recurring tasks schedule future occurrences for a rolling 90-day window,
  keyed by `taskId + occurrenceDate`.
- Never schedule `reminderAt <= now`; missed reminders are not backfilled.
- All-day tasks remind at 08:00 in the device timezone.
- Completion, cancellation, reschedule, deletion, logout, and recurrence
  exceptions must update local schedules.
- Cross-device changes are scheduled only after that device next opens Tempo
  and synchronizes. Android force-stop is outside the delivery guarantee.

Supabase must not contain notification device tokens, delivery ledgers, or a
reminder Cron/Edge Function. Historical migrations remain immutable; schema
removal is performed by a later migration.

## Android Local Reminder Delivery Contract

### 1. Scope / Trigger

Apply this contract whenever creating, editing, completing, deleting, rebuilding, or diagnosing a task with a local due-date reminder.

### 2. Signatures

```dart
Future<ReminderScheduleResult> scheduleTaskReminder(Task task, {...});
Future<ReminderScheduleResult> scheduleRecurringReminders(Task task, {...});
Future<ReminderDiagnostics> diagnostics();
```

`ReminderScheduleResult` must expose a typed status, task/notification identity, scheduled wall-clock time, and sanitized platform error when present.

### 3. Contracts

- A successful Android schedule is not established by `zonedSchedule()` returning alone; the expected stable notification ID must also appear in `pendingNotificationRequests()`.
- `scheduled` means exact AlarmManager alarm-clock scheduling is available; `scheduledInexact` means the reminder was persisted with an explicit degraded-delivery status.
- The Android notification icon must be a packaged monochrome drawable referenced by resource name, not the adaptive launcher icon.
- Task persistence and reminder persistence are separate outcomes. A task remains saved when reminder scheduling fails, while the UI reports the reminder failure.

### 4. Validation & Error Matrix

| Condition | Result | UI behavior |
|---|---|---|
| Future reminder + pending ID present | `scheduled` / `scheduledInexact` | Normal success |
| Reminder time is not future | `skippedPast` | No backfill |
| Task completed or has no schedulable due date | `skippedCompleted` | No reminder warning |
| App notifications denied | `notificationsDenied` | Open notification settings |
| Reminder channel disabled | `channelDisabled` | Open channel settings |
| Plugin returns but pending ID is absent | `pendingVerificationFailed` | Show diagnostics warning |
| Platform channel/plugin throws | `platformFailure` | Preserve sanitized error and show diagnostics warning |

### 5. Good / Base / Bad Cases

- **Good:** save task, schedule it, read back the stable ID, and expose exact/inexact status.
- **Base:** save a past or completed task and intentionally skip scheduling without presenting a platform failure.
- **Bad:** catch a plugin exception, only `debugPrint` it, and still show the same success message as a verified reminder.

### 6. Tests Required

- Assert successful schedules appear in fake pending requests with the expected stable ID.
- Assert a missing pending entry becomes `pendingVerificationFailed`.
- Assert platform exceptions become `platformFailure` with diagnostic context.
- Assert exact-alarm availability selects `alarmClock`; unavailability selects `inexactAllowWhileIdle`.
- Build the Android release APK and inspect the merged manifest for permissions/receivers and the packaged resources for the notification drawable.

### 7. Wrong vs Correct

```dart
// Wrong: release builds silently lose the only failure evidence.
try {
  await plugin.zonedSchedule(...);
} catch (error) {
  debugPrint('$error');
}

// Correct: verify platform persistence and propagate a typed result.
await plugin.zonedSchedule(...);
final pending = await plugin.pendingNotificationRequests();
return pending.any((request) => request.id == expectedId)
    ? const ReminderScheduleResult(status: ReminderScheduleStatus.scheduled)
    : const ReminderScheduleResult(
        status: ReminderScheduleStatus.pendingVerificationFailed,
      );
```
