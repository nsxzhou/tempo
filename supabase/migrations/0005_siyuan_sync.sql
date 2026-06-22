-- 思源笔记同步：绑定状态表 + 任务幂等导入

-- ============ siyuan_bindings ============
CREATE TABLE IF NOT EXISTS siyuan_bindings (
  user_id                   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  paired_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_sync_at              TIMESTAMPTZ,
  last_sync_imported_count  INT DEFAULT 0,
  plugin_version            TEXT,
  updated_at                TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE siyuan_bindings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "own_siyuan_bindings" ON siyuan_bindings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TRIGGER trg_siyuan_bindings_updated_at
  BEFORE UPDATE ON siyuan_bindings
  FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

-- ============ 同一用户同一思源块不重复导入 ============
CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_user_siyuan_block
  ON tasks(user_id, siyuan_block_id)
  WHERE siyuan_block_id IS NOT NULL;

-- ============ RPC：幂等创建思源任务 ============
CREATE OR REPLACE FUNCTION create_task_from_siyuan(
  p_title           TEXT,
  p_siyuan_block_id TEXT,
  p_description     TEXT DEFAULT NULL,
  p_due_date        TIMESTAMPTZ DEFAULT NULL,
  p_priority        SMALLINT DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
  v_list_id  UUID;
  v_task_id  UUID;
BEGIN
  SELECT id INTO v_task_id
  FROM tasks
  WHERE user_id = auth.uid()
    AND siyuan_block_id = p_siyuan_block_id
  LIMIT 1;

  IF v_task_id IS NOT NULL THEN
    RETURN v_task_id;
  END IF;

  SELECT id INTO v_list_id
  FROM task_lists
  WHERE user_id = auth.uid() AND name = 'Inbox'
  LIMIT 1;

  IF v_list_id IS NULL THEN
    INSERT INTO task_lists (user_id, name)
    VALUES (auth.uid(), 'Inbox')
    RETURNING id INTO v_list_id;
  END IF;

  INSERT INTO tasks (list_id, user_id, title, description,
                     siyuan_block_id, creation_source, due_date, priority)
  VALUES (v_list_id, auth.uid(), p_title, p_description,
          p_siyuan_block_id, 'siyuan', p_due_date, p_priority)
  RETURNING id INTO v_task_id;

  RETURN v_task_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============ RPC：插件上报绑定/同步状态 ============
CREATE OR REPLACE FUNCTION upsert_siyuan_binding(
  p_paired_at                 TIMESTAMPTZ DEFAULT NULL,
  p_last_sync_at              TIMESTAMPTZ DEFAULT NULL,
  p_last_sync_imported_count  INT DEFAULT NULL,
  p_plugin_version            TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO siyuan_bindings (
    user_id,
    paired_at,
    last_sync_at,
    last_sync_imported_count,
    plugin_version,
    updated_at
  )
  VALUES (
    auth.uid(),
    COALESCE(p_paired_at, now()),
    p_last_sync_at,
    COALESCE(p_last_sync_imported_count, 0),
    p_plugin_version,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    paired_at = COALESCE(EXCLUDED.paired_at, siyuan_bindings.paired_at),
    last_sync_at = COALESCE(EXCLUDED.last_sync_at, siyuan_bindings.last_sync_at),
    last_sync_imported_count = COALESCE(
      EXCLUDED.last_sync_imported_count,
      siyuan_bindings.last_sync_imported_count
    ),
    plugin_version = COALESCE(EXCLUDED.plugin_version, siyuan_bindings.plugin_version),
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============ RPC：App 解绑 ============
CREATE OR REPLACE FUNCTION delete_siyuan_binding()
RETURNS VOID AS $$
BEGIN
  DELETE FROM siyuan_bindings WHERE user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
