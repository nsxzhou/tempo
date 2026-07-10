# Backend Development Guidelines

> Tempo backend guidance covers local persistence (Drift/SQLite), the
> optimistic local-first sync layer (SyncTaskRepository + Supabase), app
> infrastructure providers, Supabase Edge Function proxy boundaries, and
> external integration data sources. The Flutter app still must not contain
> server-style controllers or vendor secrets.

## Guidelines Index

| Guide | Description | Status |
|-------|-------------|--------|
| [Directory Structure](./directory-structure.md) | Feature layout, services, providers, Edge Functions | Filled |
| [Database Guidelines](./database-guidelines.md) | Drift schema, optimistic sync, cloud reminder ownership, queries, migrations | Filled |
| [Error Handling](./error-handling.md) | Async data-layer error propagation and boundaries | Filled |
| [Logging Guidelines](./logging-guidelines.md) | Current no-logging baseline and future logging rules | Filled |
| [Quality Guidelines](./quality-guidelines.md) | Checks, forbidden patterns, review checklist | Filled |

## Pre-Development Checklist

Before changing backend/data code, read:

- `directory-structure.md`
- `database-guidelines.md` for Drift, schema, repository, or generated-code work
- `error-handling.md` for async providers, persistence, or network calls
- `logging-guidelines.md` before adding diagnostics
- `quality-guidelines.md`

## Quality Check

For backend/data changes, verify:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Skip `build_runner` only when no Drift/Freezed/JSON-serializable source changed.

## Source Of Truth

Document existing project conventions, not aspirational architecture. When new
patterns are introduced (e.g. a new feature repository, a new Edge Function, a
schema migration), update these spec files in the same change.
