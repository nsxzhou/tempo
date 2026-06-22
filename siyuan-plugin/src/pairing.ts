// ============================================================
// pairing.ts — 配对码输入 + token 交换 + 存储
// ============================================================

import { PAIRING_ENDPOINT } from './config';
import { initClient } from './api';
import { saveAuth, type StoredAuth } from './storage';
import { reportPaired } from './binding';

/** 配对响应 */
interface PairingResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user_email: string;
  user_id: string;
}

/** 配对错误 */
export class PairingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'PairingError';
  }
}

/** 使用配对码交换 session token */
export async function pairWithCode(code: string): Promise<StoredAuth> {
  const trimmedCode = code.trim();

  if (!trimmedCode || !/^\d{6}$/.test(trimmedCode)) {
    throw new PairingError('配对码格式无效，请输入 6 位数字');
  }

  const response = await fetch(PAIRING_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ code: trimmedCode }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({ error: '未知错误' }));
    throw new PairingError(errorData.error || `配对失败 (${response.status})`);
  }

  const data: PairingResponse = await response.json();

  const auth: StoredAuth = {
    access_token: data.access_token,
    refresh_token: data.refresh_token,
    user_email: data.user_email,
    user_id: data.user_id,
    stored_at: Date.now(),
  };

  saveAuth(auth);
  initClient(auth);
  await reportPaired();
  return auth;
}
