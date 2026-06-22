// ============================================================
// api.ts — Supabase 客户端封装
// ============================================================

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { loadAuth, saveAuth, StoredAuth } from './storage';
import { SUPABASE_ANON_KEY, SUPABASE_URL } from './config';

/** 当前 Supabase 客户端 */
let client: SupabaseClient | null = null;
let currentAuth: StoredAuth | null = null;

/** 初始化 Supabase 客户端 */
export function initClient(auth: StoredAuth): SupabaseClient {
  currentAuth = auth;
  client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      headers: {
        Authorization: `Bearer ${auth.access_token}`,
      },
    },
  });
  return client;
}

/** 获取当前 Supabase 客户端 */
export function getClient(): SupabaseClient | null {
  if (!client) {
    const auth = loadAuth();
    if (auth) {
      return initClient(auth);
    }
  }
  return client;
}

/** 刷新 session（access_token 过期时） */
export async function refreshSession(): Promise<boolean> {
  if (!currentAuth) {
    const auth = loadAuth();
    if (!auth) return false;
    currentAuth = auth;
  }

  try {
    const response = await fetch(
      `${SUPABASE_URL}/auth/v1/token?grant_type=refresh_token`,
      {
        method: 'POST',
        headers: {
          apikey: SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          refresh_token: currentAuth.refresh_token,
        }),
      }
    );

    if (!response.ok) return false;

    const session = await response.json();
    const newAuth: StoredAuth = {
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      user_email: currentAuth.user_email,
      user_id: currentAuth.user_id,
      stored_at: Date.now(),
    };

    saveAuth(newAuth);
    initClient(newAuth);
    return true;
  } catch {
    return false;
  }
}

async function withAuthRetry<T>(action: () => Promise<T>): Promise<T> {
  try {
    return await action();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('JWT') || message.includes('401')) {
      const refreshed = await refreshSession();
      if (refreshed) {
        return await action();
      }
    }
    throw error;
  }
}

/** 通过 RPC 创建任务（思源导入） */
export async function createTaskFromSiyuan(
  title: string,
  siyuanBlockId: string,
  description?: string | null,
  dueDate?: string | null,
  priority?: number
): Promise<string> {
  return withAuthRetry(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');

    const { data, error } = await supabase.rpc('create_task_from_siyuan', {
      p_title: title,
      p_siyuan_block_id: siyuanBlockId,
      p_description: description ?? null,
      p_due_date: dueDate ?? null,
      p_priority: priority ?? 0,
    });

    if (error) throw error;
    return data as string;
  });
}

export { SUPABASE_URL, SUPABASE_ANON_KEY };
export { PAIRING_ENDPOINT } from './config';
