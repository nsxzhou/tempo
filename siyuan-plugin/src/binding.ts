// ============================================================
// binding.ts — 上报绑定/同步状态到 Supabase
// ============================================================

import { getClient } from './api';
import { PLUGIN_VERSION } from './config';

/** 配对成功后上报 */
export async function reportPaired(): Promise<void> {
  const supabase = getClient();
  if (!supabase) return;

  const { error } = await supabase.rpc('upsert_siyuan_binding', {
    p_paired_at: new Date().toISOString(),
    p_plugin_version: PLUGIN_VERSION,
  });

  if (error) {
    console.warn('[Tempo] reportPaired failed:', error.message);
  }
}

/** 扫描完成后上报 */
export async function reportSync(importedCount: number): Promise<void> {
  const supabase = getClient();
  if (!supabase) return;

  const { error } = await supabase.rpc('upsert_siyuan_binding', {
    p_last_sync_at: new Date().toISOString(),
    p_last_sync_imported_count: importedCount,
    p_plugin_version: PLUGIN_VERSION,
  });

  if (error) {
    console.warn('[Tempo] reportSync failed:', error.message);
  }
}

/** 解绑时删除绑定记录 */
export async function reportUnpaired(): Promise<void> {
  const supabase = getClient();
  if (!supabase) return;

  const { error } = await supabase.rpc('delete_siyuan_binding');
  if (error) {
    console.warn('[Tempo] reportUnpaired failed:', error.message);
  }
}
