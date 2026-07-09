-- ============================================================
-- Tempo — 远端任务提醒设备与发送幂等
-- ============================================================

CREATE TABLE IF NOT EXISTS notification_devices (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  fcm_token    TEXT NOT NULL UNIQUE,
  platform     TEXT NOT NULL,
  timezone     TEXT NOT NULL DEFAULT 'Asia/Shanghai',
  enabled      BOOLEAN NOT NULL DEFAULT true,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_devices_user_enabled
  ON notification_devices(user_id, enabled);

ALTER TABLE notification_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_notification_devices" ON notification_devices
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TRIGGER trg_notification_devices_updated_at
  BEFORE UPDATE ON notification_devices
  FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

CREATE TABLE IF NOT EXISTS notification_deliveries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id       UUID REFERENCES notification_devices(id) ON DELETE CASCADE NOT NULL,
  task_id         UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  occurrence_date DATE,
  reminder_at     TIMESTAMPTZ NOT NULL,
  sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  status          TEXT NOT NULL DEFAULT 'sent',
  error           TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_notification_deliveries_unique_reminder
  ON notification_deliveries(
    device_id,
    task_id,
    COALESCE(occurrence_date, DATE '0001-01-01'),
    reminder_at
  );

CREATE INDEX IF NOT EXISTS idx_notification_deliveries_task
  ON notification_deliveries(task_id);

ALTER TABLE notification_deliveries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_notification_deliveries" ON notification_deliveries
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM notification_devices d
      WHERE d.id = device_id AND d.user_id = auth.uid()
    )
  );
