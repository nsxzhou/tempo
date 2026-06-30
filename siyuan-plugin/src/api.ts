// ============================================================
// api.ts — Supabase 客户端封装
// ============================================================

import {
  createClient,
  PostgrestError,
  SupabaseClient,
} from '@supabase/supabase-js';
import { clearAuth, loadAuth, saveAuth, StoredAuth } from './storage';
import { SUPABASE_ANON_KEY, SUPABASE_URL } from './config';

/** 当前 Supabase 客户端 */
let client: SupabaseClient | null = null;
let currentAuth: StoredAuth | null = null;
let refreshInFlight: Promise<boolean> | null = null;

const REFRESH_SKEW_MS = 60_000;

function isAuthError(error: PostgrestError | null): boolean {
  if (!error) return false;
  const message = error.message.toLowerCase();
  return (
    error.code === 'PGRST301' ||
    message.includes('jwt') ||
    message.includes('401') ||
    message.includes('invalid claim')
  );
}

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

/** 重置客户端（解绑时） */
export function resetClient(): void {
  client = null;
  currentAuth = null;
  refreshInFlight = null;
}

function expiresAtFromSession(session: { expires_at?: number; expires_in?: number }): number {
  if (typeof session.expires_at === 'number' && session.expires_at > 0) {
    return session.expires_at * 1000;
  }
  const expiresIn = typeof session.expires_in === 'number' ? session.expires_in : 3600;
  return Date.now() + expiresIn * 1000;
}

function shouldRefresh(auth: StoredAuth): boolean {
  if (!auth.expires_at) return true;
  return auth.expires_at - Date.now() <= REFRESH_SKEW_MS;
}

function isInvalidRefreshToken(status: number, body: string): boolean {
  if (![400, 401, 403].includes(status)) return false;
  const text = body.toLowerCase();
  return (
    text.includes('refresh') ||
    text.includes('invalid') ||
    text.includes('expired') ||
    text.includes('not found')
  );
}

/** 请求前确保 access_token 未临近过期。 */
export async function ensureFreshSession(): Promise<boolean> {
  if (!currentAuth) {
    const auth = loadAuth();
    if (!auth) return false;
    currentAuth = auth;
    initClient(auth);
  }

  if (!shouldRefresh(currentAuth)) return true;
  return refreshSession();
}

/** 刷新 session（access_token 过期时） */
export async function refreshSession(): Promise<boolean> {
  if (refreshInFlight) return refreshInFlight;

  refreshInFlight = refreshSessionOnce().finally(() => {
    refreshInFlight = null;
  });
  return refreshInFlight;
}

async function refreshSessionOnce(): Promise<boolean> {
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

    if (!response.ok) {
      const body = await response.text().catch(() => '');
      if (isInvalidRefreshToken(response.status, body)) {
        clearAuth();
        resetClient();
      }
      return false;
    }

    const session = await response.json();
    const newAuth: StoredAuth = {
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      user_email: currentAuth.user_email,
      user_id: currentAuth.user_id,
      expires_at: expiresAtFromSession(session),
      stored_at: Date.now(),
    };

    saveAuth(newAuth);
    initClient(newAuth);
    return true;
  } catch {
    return false;
  }
}

/** Supabase 请求失败时尝试刷新 token 并重试 */
export async function withAuthRetry<T>(
  action: () => Promise<{ data: T | null; error: PostgrestError | null }>
): Promise<T> {
  await ensureFreshSession();
  let result = await action();

  if (result.error && isAuthError(result.error)) {
    const refreshed = await refreshSession();
    if (refreshed) {
      result = await action();
    }
  }

  if (result.error) {
    throw new Error(result.error.message);
  }

  if (result.data === null) {
    throw new Error('Supabase 返回空数据');
  }

  return result.data;
}

/** 无返回体的 Supabase 写操作 */
export async function withAuthRetryVoid(
  action: () => Promise<{ error: PostgrestError | null }>
): Promise<void> {
  await ensureFreshSession();
  let result = await action();

  if (result.error && isAuthError(result.error)) {
    const refreshed = await refreshSession();
    if (refreshed) {
      result = await action();
    }
  }

  if (result.error) {
    throw new Error(result.error.message);
  }
}

export { SUPABASE_URL, SUPABASE_ANON_KEY };
export { PAIRING_ENDPOINT } from './config';
