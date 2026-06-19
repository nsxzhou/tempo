-- ============================================================
-- Tempo Phase 1 — Supabase Storage: 语音音频临时存储
-- 用途: 语音创建任务时，Edge Function 将录音上传到此 bucket，
--       生成 signed URL 供火山引擎 ASR 访问，识别完成后自动删除。
-- ============================================================

-- 创建私有 bucket（不公开，Edge Function 通过 service_role 操作）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'tempo-audio',
  'tempo-audio',
  false,
  10485760,  -- 10 MB 上限
  ARRAY['audio/mp4', 'audio/x-m4a', 'audio/m4a', 'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg']
)
ON CONFLICT (id) DO NOTHING;

-- RLS: 认证用户可上传（Edge Function 用 service_role 绕过，此为防御层）
CREATE POLICY "auth_users_upload_own_audio"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'tempo-audio'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- RLS: 用户只能读/删自己上传的文件
CREATE POLICY "auth_users_read_own_audio"
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'tempo-audio'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "auth_users_delete_own_audio"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'tempo-audio'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
