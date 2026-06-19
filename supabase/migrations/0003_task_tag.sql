-- 新增 tasks.tag 列：工作/生活分类（nullable）
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS tag TEXT;
