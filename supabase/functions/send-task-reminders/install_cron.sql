-- Replace placeholders before running in the Supabase SQL editor.
DO $$
DECLARE
  existing_job BIGINT;
BEGIN
  SELECT jobid INTO existing_job
  FROM cron.job
  WHERE jobname = 'tempo-task-reminders';

  IF existing_job IS NOT NULL THEN
    PERFORM cron.unschedule(existing_job);
  END IF;
END $$;

SELECT cron.schedule(
  'tempo-task-reminders',
  '* * * * *',
  $cron$
  SELECT net.http_post(
    url := 'https://<project-ref>.functions.supabase.co/send-task-reminders',
    headers := jsonb_build_object(
      'Authorization', 'Bearer <REMINDER_CRON_SECRET>',
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $cron$
);

SELECT jobid, jobname, schedule, active
FROM cron.job
WHERE jobname = 'tempo-task-reminders';
