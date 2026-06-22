import { DEFAULT_LIST_NAME, TABLE_TASK_LISTS } from '../constants';
import { getClient, withAuthRetry } from '../api';
import { loadAuth } from '../storage';

let cachedListId: string | null = null;

export async function getOrCreateInboxListId(): Promise<string> {
  if (cachedListId) return cachedListId;

  const auth = loadAuth();
  if (!auth) throw new Error('未绑定 Tempo 账号');

  const existing = await withAuthRetry<{ id: string } | null>(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');
    return supabase
      .from(TABLE_TASK_LISTS)
      .select('id')
      .eq('name', DEFAULT_LIST_NAME)
      .maybeSingle();
  });

  if (existing?.id) {
    cachedListId = existing.id;
    return cachedListId;
  }

  const created = await withAuthRetry<{ id: string }>(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');
    return supabase
      .from(TABLE_TASK_LISTS)
      .insert({ user_id: auth.user_id, name: DEFAULT_LIST_NAME })
      .select('id')
      .single();
  });

  cachedListId = created.id;
  return cachedListId;
}

export function resetListCache(): void {
  cachedListId = null;
}
