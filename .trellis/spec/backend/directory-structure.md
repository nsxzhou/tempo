# Backend Directory Structure

> Backend-like code in Tempo currently means local persistence, external-service
> integration boundaries, and app-wide providers. There is no separate server
> package yet.

## Current Layout

```text
supabase/
├── config.toml                         # Supabase local dev config
├── migrations/
│   ├── 0001_init.sql                   # task_lists + tasks tables
│   └── 0002_audio_storage.sql          # tempo-audio storage bucket
└── functions/
    ├── parse-task/index.ts             # Text → structured task (LLM)
    ├── voice-task/index.ts             # Audio → transcript → task (ASR + LLM)
    └── siyuan-pairing/index.ts         # SiYuan note ↔ task binding

lib/
├── main.dart                           # Entry: Supabase + dotenv + timezone init
├── app.dart                            # Root widget (TempoApp, ConsumerStatefulWidget)
├── app_providers.dart                  # All global Riverpod providers
├── core/
│   ├── constants/app_constants.dart    # Routes, priorities, Supabase config, table names
│   ├── providers/
│   │   └── database_provider.dart      # Drift DB singleton provider
│   ├── router/
│   │   ├── app_router.dart             # GoRouter config with auth + onboarding guards
│   │   └── shell_scaffold.dart         # Bottom tab bar shell (4 tabs)
│   ├── theme/app_theme.dart            # Light/dark theme + design tokens
│   ├── utils/                          # Shared utilities
│   └── widgets/
│       ├── tempo/                      # Shared component library
│       ├── empty_state.dart
│       └── feature_unavailable_page.dart
├── database/
│   ├── tables.dart                     # Drift table definitions (TaskLists, Tasks)
│   ├── database.dart                   # AppDatabase (schema v5) + migrations
│   └── database.g.dart                 # Generated Drift code, committed
└── features/
    ├── auth/                           # Supabase auth service + login page
    │   ├── data/auth_service.dart
    │   └── presentation/
    ├── tasks/                          # Most mature feature
    │   ├── data/
    │   │   ├── task_repository.dart    # TaskRepository interface + SyncTaskRepository
    │   │   ├── sync_service.dart       # Connectivity-aware background sync
    │   │   ├── text_parse_service.dart # Natural language → task fields (LLM)
    │   │   ├── streaming_voice_session.dart # Recorder + streaming ASR orchestration
    │   │   ├── volcengine_streaming_asr.dart # ASR session + relay client
    │   │   ├── voice_recorder.dart     # Push-to-talk recording interface
    │   │   └── notification_service.dart # Local fallback + foreground notifications
    │   ├── domain/
    │   │   ├── task.dart               # Freezed Task model + TaskPriority enum
    │   │   ├── task.g.dart
    │   │   └── task.freezed.dart
    │   └── presentation/               # TasksPage, TaskDetailPage, widgets
    ├── calendar/                       # Day/week/month calendar views
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── voice/                          # Voice input UI (push-to-talk FAB)
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── ai_planner/                     # AI schedule planner (Phase 2)
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── settings/                       # App settings + SiYuan pairing + feedback
    │   ├── data/
    │   │   ├── siyuan_pairing_service.dart  # SiYuan note binding via Edge Function
    │   │   └── feedback_service.dart        # Shake-to-feedback via Supabase
    │   ├── domain/
    │   └── presentation/
    └── onboarding/                     # First-launch onboarding flow
        ├── data/
        └── presentation/
```

## Module Boundaries

- Keep storage schema in `lib/database/`. `tables.dart` owns Drift table
  definitions; `database.dart` owns `AppDatabase`, connection setup, schema
  versioning, and migrations.
- Keep global infrastructure providers in `lib/core/providers/`. Example:
  `lib/core/providers/database_provider.dart` creates and disposes the
  `AppDatabase` singleton through Riverpod.
- Feature-specific data access lives under `lib/features/<feature>/data/`.
  The `tasks` feature demonstrates the full pattern: `TaskRepository`
  interface + `SyncTaskRepository` implementation, plus service classes
  (`SyncService`, `TextParseService`, `StreamingVoiceSession`,
  `VolcengineStreamingAsr`, `NotificationService`). Do not add feature query
  methods directly to UI widgets.
- Keep Supabase Edge Functions under `supabase/functions/<function-name>/`.
  They are external-service proxy boundaries, not Flutter feature code. Any
  API keys, ASR tokens, LLM keys, or vendor credentials must stay in function
  environment variables and must not be exposed through the mobile app.
  Current functions: `parse-task` (LLM text parsing), `voice-task` (ASR +
  LLM), `siyuan-pairing` (note binding).
- Keep domain models under `lib/features/<feature>/domain/`. Example:
  `lib/features/tasks/domain/task.dart` defines the `Task` Freezed value
  object and `TaskPriority` enum.
- `lib/app_providers.dart` is the composition layer for all app-level
  providers. Every new service gets a provider here. Current providers:
  `dioProvider`, `connectivityProvider`, `taskRepositoryProvider`,
  `taskListProvider`, `taskMapProvider`, `taskByIdProvider`,
  `taskCountsProvider`, `calendarTaskIndexProvider`, `syncServiceProvider`,
  `notificationServiceProvider`, `remoteNotificationServiceProvider`, `textParseServiceProvider`,
  `voiceRecorderProvider`, `asrSessionClientProvider`,
  `volcengineStreamingAsrProvider`, `streamingVoiceSessionProvider`,
  `siyuanPairingServiceProvider`, `siyuanBindingStatusProvider`,
  `feedbackServiceProvider`, `defaultListIdProvider`. Auth-related providers
  are defined in `features/auth/data/auth_service.dart` and re-exported.

## Naming Conventions

- Dart files use `snake_case.dart`.
- Classes use `UpperCamelCase`: `AppDatabase`, `Task`, `TaskCounts`.
- Providers use lower camel case and end in `Provider`: `databaseProvider`,
  `taskListProvider`.
- Drift table classes are plural nouns: `TaskLists`, `Tasks`.
- Generated files stay next to their source files and are committed when the
  source uses `part`: `database.g.dart`, `task.freezed.dart`, `task.g.dart`.

## Examples To Follow

- `lib/database/tables.dart`: table definitions are grouped by entity and keep
  column defaults close to the column declaration.
- `lib/database/database.dart`: database setup, migrations, and convenience
  queries stay behind `AppDatabase`.
- `lib/core/providers/database_provider.dart`: infrastructure lifecycle is
  owned by Riverpod via `ref.onDispose(() => db.close())`.
- `lib/features/tasks/domain/task.dart`: feature domain models use Freezed and
  JSON serialization parts.

## Avoid

- Do not create a second database connection in feature UI code.
- Do not put persistence code in `presentation/` widgets.
- Do not put generated code in `.gitignore`; current build depends on committed
  Drift/Freezed part files.
- Do not introduce server-style route/controller directories under `lib/`.
  Server-side proxy code belongs under `supabase/functions/`.

## Scenario: Supabase Edge Function Proxy Boundary

### 1. Scope / Trigger

- Trigger: adding an external-service integration that mobile code calls
  through a Supabase Edge Function.
- Use this pattern when the integration needs secrets, vendor tokens, or
  normalized request/response contracts shared across Flutter and tests.

### 2. Signatures

- Function path: `supabase/functions/<name>/index.ts`
- Optional docs: `supabase/functions/<name>/README.md`
- Flutter calls the function through a feature data service, for example:

```dart
final result = await ref.read(textParseServiceProvider).parseText(text);
```

### 3. Contracts

- Request: define one accepted primary shape and any test-only shape in the
  function README. For text task parsing:
  - JSON with the natural-language input text
- Response: return normalized JSON with stable field names. For voice task
  creation / text parsing:
  - `title: string`
  - `description: string | null`
  - `due_date: string | null` as ISO-8601
  - `priority: number`
  - `confidence: number`
  - `raw_transcript: string`
- Environment keys must be listed in the README. Flutter may configure only
  the function endpoint; it must not contain vendor secrets.

### 4. Validation & Error Matrix

- Missing request body or required file -> HTTP 500 with `{ "error": "..." }`
  during the spike; harden to 400 before production.
- Missing required environment variable -> HTTP 500 with a sanitized missing
  variable name.
- Vendor ASR/LLM non-2xx response -> HTTP 500 with vendor name and status.
- Invalid vendor response shape -> HTTP 500 and no local task creation.
- Flutter service invalid JSON -> throw at the data boundary; UI surfaces a
  user-facing failure and does not write Drift.

### 5. Good/Base/Bad Cases

- Good: credentials configured, vendor calls succeed, function returns
  normalized JSON, Flutter data service maps it into typed domain data.
- Base: mock mode enabled for local development, function returns a fixed
  response without external calls.
- Bad: Flutter calls vendor endpoints directly or parses vendor-specific JSON
  in a widget.

### 6. Tests Required

- Unit test the Flutter response decoder with valid, low-confidence, and
  malformed payloads.
- Widget/provider test the user-facing failure path so backend errors do not
  create local records.
- Run `deno check supabase/functions/<name>/index.ts` when Deno is available.
- External vendor calls require credentialed manual validation; do not block
  app unit tests on live ASR/LLM services.

### 7. Wrong vs Correct

#### Wrong

```dart
// Widget knows the vendor URL and token.
await Dio().post('https://vendor.example/asr', options: Options(headers: {
  'Authorization': 'Bearer secret',
}));
```

#### Correct

```dart
// Widget calls a feature service; credentials stay in the Edge Function.
final result = await ref.read(textParseServiceProvider).parseText(text);
```
