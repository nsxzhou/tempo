# send-task-reminders

Scheduled Supabase Edge Function for cross-device Tempo reminders.

## Required Secrets

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `FIREBASE_SERVICE_ACCOUNT_JSON` — full Firebase service account JSON with Firebase Cloud Messaging permission.
- `REMINDER_CRON_SECRET` — optional bearer token checked on function calls.

## Schedule

Call every minute from Supabase Cron:

```sql
select cron.schedule(
  'tempo-task-reminders',
  '* * * * *',
  $$
  select net.http_post(
    url := 'https://<project-ref>.functions.supabase.co/send-task-reminders',
    headers := jsonb_build_object(
      'Authorization', 'Bearer <REMINDER_CRON_SECRET>',
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);
```

The function scans enabled `notification_devices`, computes the current
one-minute local-time window per device timezone, writes a
`notification_deliveries` row for idempotency, then sends FCM HTTP v1 messages.

Server-side recurring reminders currently support the app's common `RRULE`
forms for `FREQ=DAILY`, `FREQ=WEEKLY` with optional `BYDAY`, and
`FREQ=MONTHLY` with optional `BYMONTHDAY`, plus `INTERVAL`, `COUNT`, `UNTIL`,
completion rows, and cancellation exceptions.
