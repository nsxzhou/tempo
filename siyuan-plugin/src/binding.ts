// ============================================================
// binding.ts — 上报绑定/同步状态到 Supabase
// ============================================================

import { getClient, withAuthRetryVoid } from './api';
import { PLUGIN_VERSION } from './config';

/** 配对成功后上报 */
export async function reportPaired(): Promise<void> {
  try {
    await withAuthRetryVoid(async () => {
      const supabase = getClient();
      if (!supabase) throw new Error('未绑定 Tempo 账号');

      return supabase.rpc('upsert_siyuan_binding', {
        p_paired_at: new Date().toISOString(),
        p_plugin_version: PLUGIN_VERSION,
      });
    });
  } catch (error) {
    console.warn(
      '[Tempo] reportPaired failed:',
      error instanceof Error ? error.message : String(error)
    );
  }
}

/** 解绑时删除绑定记录 */
export async function reportUnpaired(): Promise<void> {
  try {
    await withAuthRetryVoid(async () => {
      const supabase = getClient();
      if (!supabase) throw new Error('未绑定 Tempo 账号');

      return supabase.rpc('delete_siyuan_binding');
    });
  } catch (error) {
    console.warn(
      '[Tempo] reportUnpaired failed:',
      error instanceof Error ? error.message : String(error)
    );
  }
}
