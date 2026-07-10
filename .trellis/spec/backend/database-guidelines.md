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

## Cloud Reminder Ownership Contract

### Scope / Trigger

Apply this contract whenever task persistence, sync state, local notifications,
FCM payloads, or `notification_deliveries` change.

### Signatures

- `SyncTaskRepository(..., onTaskSynced: Future<void> Function(String taskId)?)`
- `NotificationService.markTaskSynced(String taskId)` cancels the temporary
  local reminder after a successful cloud upsert.
- `notification_deliveries.attempt_count INT NOT NULL DEFAULT 1`
- `notification_deliveries.last_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now()`
- `claim_notification_delivery_retry(device, task, occurrence, reminder_at, now)`
  returns whether a failed delivery was atomically claimed for retry.

### Contracts

- Unsynced (`syncPending=true`) tasks own a local reminder.
- A synced task becomes cloud-owned only after its FCM token is successfully
  written to `notification_devices`; login state alone is not sufficient.
- If Firebase initialization, token retrieval, or device upsert fails, synced
  tasks retain local scheduled reminders.
- A recurring local fallback schedules only the next pending occurrence.
- FCM data includes `reminderKey`, `taskId`, `occurrenceDate`, and `reminderAt`.
- The reminder Edge Function only considers reminders in the previous two
  minutes through the actual invocation time. It never sends future reminders
  early and never backfills older reminders.

### Validation & Error Matrix

| Condition | Required behavior |
|---|---|
| task cloud upsert succeeds, FCM registered | persist `syncPending=false`, then cancel local reminder |
| task cloud upsert succeeds, FCM unavailable | retain the existing local fallback |
| task cloud upsert fails | retain `syncPending=true` and local fallback |
| FCM succeeds | mark delivery `sent`; unique key prevents another send |
| transient FCM failure within 2 minutes | mark `failed`; RPC may claim at most two retries |
| failure is older than 2 minutes | keep failed record; do not resend |
| invalid FCM token | record failure and remove the device token |
| user signs out | disable the current token and clear local schedules |

### Good / Base / Bad Cases

- Good: offline task gets one local reminder; sync success cancels it; FCM owns
  all later occurrences.
- Base: Cron runs late by one minute and retries the same failed delivery once.
- Bad: scheduling 14 local occurrences for a cloud-owned repeating task, which
  can leave stale notifications and duplicate FCM.

### Tests Required

- Assert recurring local fallback creates exactly one pending notification.
- Assert cloud-owned tasks create no local schedule.
- Assert sync success invokes `onTaskSynced` for immediate and queued upserts.
- Assert recurrence COUNT counts actual occurrences, including multi-day weekly
  rules.
- Assert the server window excludes future reminders and reminders older than
  two minutes.
- Assert foreground FCM is converted to one system notification using the
  stable reminder key.

### Wrong vs Correct

```dart
// Wrong: cloud-owned series also reserves many local alarms.
for (final occurrence in futureOccurrences.take(14)) {
  await schedule(occurrence);
}

// Correct: only an unsynced/local-owned task gets the next fallback alarm.
if (task.syncPending) {
  await schedule(engine.nextOccurrence(task));
}
```
