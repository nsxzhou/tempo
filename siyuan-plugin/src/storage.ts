// ============================================================
// storage.ts — localStorage token 存储管理
// key: 'tempo_siyuan_auth'
// ============================================================

const STORAGE_KEY = 'tempo_siyuan_auth';

/** 存储的认证信息 */
export interface StoredAuth {
  access_token: string;
  refresh_token: string;
  user_email: string;
  user_id: string;
  /** Epoch milliseconds when the access token expires. Missing legacy values are treated as stale. */
  expires_at?: number;
  stored_at: number;
}

/** 保存认证信息到 localStorage */
export function saveAuth(auth: StoredAuth): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(auth));
}

/** 从 localStorage 加载认证信息 */
export function loadAuth(): StoredAuth | null {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as StoredAuth;
  } catch {
    return null;
  }
}

/** 清除 localStorage 中的认证信息（解绑） */
export function clearAuth(): void {
  localStorage.removeItem(STORAGE_KEY);
}

/** 检查是否已绑定 */
export function isPaired(): boolean {
  return loadAuth() !== null;
}
