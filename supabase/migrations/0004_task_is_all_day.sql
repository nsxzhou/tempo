-- 任务全天标记：有日期但未指定具体时间时使用
ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS is_all_day BOOLEAN DEFAULT false NOT NULL;
