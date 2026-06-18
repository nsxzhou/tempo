-- ============================================================
-- Tempo Phase 1 — Supabase 初始化迁移
-- 包含: 建表 + RLS + 索引 + 触发器 + RPC
-- ============================================================

-- ============ task_lists ============
CREATE TABLE IF NOT EXISTS task_lists (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ============ tasks ============
CREATE TABLE IF NOT EXISTS tasks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id         UUID REFERENCES task_lists(id) ON DELETE CASCADE NOT NULL,
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  priority        SMALLINT DEFAULT 0,   -- 0=none 1=P0 2=P1 3=P2 4=P3
  due_date        TIMESTAMPTZ,
  is_completed    BOOLEAN DEFAULT false,
  completed_at    TIMESTAMPTZ,
  siyuan_block_id TEXT,
  sort_order      INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  creation_source TEXT DEFAULT 'text'   -- text|voice|siyuan|ai
);

-- ============ siyuan_pairing_codes ============
CREATE TABLE IF NOT EXISTS siyuan_pairing_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT NOT NULL,             -- 6 位数字
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  user_email  TEXT NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,      -- 创建后 5 分钟
  used_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ============ feedback ============
CREATE TABLE IF NOT EXISTS feedback (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content      TEXT NOT NULL,
  device_info  JSONB,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- ============ 索引 ============
CREATE INDEX idx_tasks_user_id        ON tasks(user_id);
CREATE INDEX idx_tasks_list_id        ON tasks(list_id);
CREATE INDEX idx_tasks_due_date       ON tasks(due_date);
CREATE INDEX idx_tasks_is_completed   ON tasks(is_completed);
CREATE INDEX idx_pairing_codes_code   ON siyuan_pairing_codes(code);

-- ============ RLS 策略 ============
ALTER TABLE task_lists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_task_lists" ON task_lists
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_tasks" ON tasks
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE siyuan_pairing_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_pairing_codes" ON siyuan_pairing_codes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "create_own_feedback" ON feedback
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "read_own_feedback" ON feedback
  FOR SELECT USING (auth.uid() = user_id);

-- ============ 触发器 ============
-- 自动更新 updated_at
CREATE OR REPLACE FUNCTION fn_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

-- 新用户自动创建默认 Inbox 列表
CREATE OR REPLACE FUNCTION fn_create_default_list()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO task_lists (user_id, name)
  VALUES (NEW.id, 'Inbox');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION fn_create_default_list();

-- ============ RPC：思源插件创建任务 ============
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
