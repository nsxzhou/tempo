-- Tempo reminders are local-only. Remove the retired FCM delivery backend.
DO $$
DECLARE
  reminder_job_id BIGINT;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron') THEN
    FOR reminder_job_id IN
      EXECUTE 'SELECT jobid FROM cron.job WHERE jobname = ''tempo-task-reminders'''
    LOOP
      EXECUTE format('SELECT cron.unschedule(%s)', reminder_job_id);
    END LOOP;
  END IF;
END;
$$;

DROP FUNCTION IF EXISTS claim_notification_delivery_retry(
  UUID,
  UUID,
  DATE,
  TIMESTAMPTZ,
  TIMESTAMPTZ
);

DROP TABLE IF EXISTS notification_deliveries;
DROP TABLE IF EXISTS notification_devices;
