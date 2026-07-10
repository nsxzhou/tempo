-- Add bounded retry metadata for task reminder delivery.
ALTER TABLE notification_deliveries
  ADD COLUMN IF NOT EXISTS attempt_count INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS last_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE OR REPLACE FUNCTION claim_notification_delivery_retry(
  p_device_id UUID,
  p_task_id UUID,
  p_occurrence_date DATE,
  p_reminder_at TIMESTAMPTZ,
  p_now TIMESTAMPTZ
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  claimed_id UUID;
BEGIN
  UPDATE notification_deliveries
  SET status = 'pending',
      error = NULL,
      attempt_count = attempt_count + 1,
      last_attempt_at = p_now
  WHERE device_id = p_device_id
    AND task_id = p_task_id
    AND occurrence_date IS NOT DISTINCT FROM p_occurrence_date
    AND reminder_at = p_reminder_at
    AND status = 'failed'
    AND attempt_count < 3
    AND p_now >= reminder_at
    AND p_now < reminder_at + INTERVAL '2 minutes'
  RETURNING id INTO claimed_id;

  RETURN claimed_id IS NOT NULL;
END;
$$;

REVOKE ALL ON FUNCTION claim_notification_delivery_retry(UUID, UUID, DATE, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION claim_notification_delivery_retry(UUID, UUID, DATE, TIMESTAMPTZ, TIMESTAMPTZ) TO service_role;
