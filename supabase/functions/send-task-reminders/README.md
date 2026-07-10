# send-task-reminders

Scheduled Supabase Edge Function for cross-device Tempo reminders.

## Required Secrets

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `FIREBASE_SERVICE_ACCOUNT_JSON` — full Firebase service account JSON with Firebase Cloud Messaging permission.
- `REMINDER_CRON_SECRET` — optional bearer token checked on function calls.

## Schedule

Run `supabase/functions/send-task-reminders/install_cron.sql` in the Supabase SQL editor after replacing the two placeholders. The script removes an old job with the same name, creates a one-minute schedule, and returns the installed job for verification.

Verify later with:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname = 'tempo-task-reminders';

select status, count(*)
from notification_deliveries
where sent_at > now() - interval '24 hours'
group by status;
```

The function considers the current and immediately previous minute, allowing a transient failure to retry within two minutes. Reminders older than that are never backfilled.

The function scans enabled `notification_devices`, computes the current
one-minute local-time window per device timezone, writes a
`notification_deliveries` row for idempotency, then sends FCM HTTP v1 messages.

Server-side recurring reminders currently support the app's common `RRULE`
forms for `FREQ=DAILY`, `FREQ=WEEKLY` with optional `BYDAY`, and
`FREQ=MONTHLY` with optional `BYMONTHDAY`, plus `INTERVAL`, `COUNT`, `UNTIL`,
completion rows, and cancellation exceptions.
