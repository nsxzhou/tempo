-- ============================================================
-- Tempo — 重复任务 / 打卡
-- tasks 新增 recurrence 字段 + 例外表 + 完成记录表
-- ============================================================

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS recurrence_rule   TEXT,
  ADD COLUMN IF NOT EXISTS recurrence_end     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS recurrence_count   INT,
  ADD COLUMN IF NOT EXISTS duration_min       INT,
  ADD COLUMN IF NOT EXISTS recurrence_series_id UUID REFERENCES tasks(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_recurrence_rule
  ON tasks(recurrence_rule) WHERE recurrence_rule IS NOT NULL;

-- ============ task_recurrence_exceptions ============
CREATE TABLE IF NOT EXISTS task_recurrence_exceptions (
  task_id          UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  exception_date   DATE NOT NULL,
  override_due     TIMESTAMPTZ,
  override_title   TEXT,
  is_cancelled     BOOLEAN NOT NULL DEFAULT false,
  PRIMARY KEY (task_id, exception_date)
);

ALTER TABLE task_recurrence_exceptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_task_recurrence_exceptions" ON task_recurrence_exceptions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_id AND t.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_id AND t.user_id = auth.uid())
  );

-- ============ task_completions ============
CREATE TABLE IF NOT EXISTS task_completions (
  task_id           UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  occurrence_date   DATE NOT NULL,
  completed_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (task_id, occurrence_date)
);

CREATE INDEX IF NOT EXISTS idx_task_completions_task_id
  ON task_completions(task_id);

ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_task_completions" ON task_completions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_id AND t.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_id AND t.user_id = auth.uid())
  );
