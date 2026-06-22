import { SOURCE_TEXT, TABLE_TASKS } from '../constants';
import {
  Task,
  taskFromSupabaseJson,
  taskToSupabaseJson,
  TaskPriority,
} from '../models/task';
import { getClient, withAuthRetry, withAuthRetryVoid } from '../api';
import { getOrCreateInboxListId } from './list_repository';
import { loadAuth } from '../storage';

function mapRows(rows: Record<string, unknown>[]): Task[] {
  return rows.map((row) => taskFromSupabaseJson(row));
}

export async function fetchTasks(): Promise<Task[]> {
  const auth = loadAuth();
  if (!auth) throw new Error('未绑定 Tempo 账号');

  const rows = await withAuthRetry<Record<string, unknown>[]>(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');

    return supabase
      .from(TABLE_TASKS)
      .select('*')
      .eq('user_id', auth.user_id)
      .order('is_completed', { ascending: true })
      .order('priority', { ascending: true })
      .order('due_date', { ascending: false, nullsFirst: false })
      .order('created_at', { ascending: false });
  });

  return mapRows(rows);
}

export interface TaskFormInput {
  title: string;
  description?: string | null;
  priority?: TaskPriority;
  dueDate?: Date | null;
  isAllDay?: boolean;
  tag?: string | null;
}

export interface CreateTaskInput extends TaskFormInput {}

export async function createTask(input: CreateTaskInput): Promise<Task> {
  const auth = loadAuth();
  if (!auth) throw new Error('未绑定 Tempo 账号');

  const trimmedTitle = input.title.trim();
  if (!trimmedTitle) {
    throw new Error('任务标题不能为空');
  }

  const listId = await getOrCreateInboxListId();
  const id = crypto.randomUUID();

  const row = await withAuthRetry<Record<string, unknown>>(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');

    return supabase
      .from(TABLE_TASKS)
      .insert(
        taskToSupabaseJson(
          {
            id,
            listId,
            title: trimmedTitle,
            description: input.description ?? null,
            priority: input.priority ?? TaskPriority.none,
            dueDate: input.dueDate ?? null,
            isAllDay: input.isAllDay ?? false,
            isCompleted: false,
            completedAt: null,
            sortOrder: 0,
            creationSource: SOURCE_TEXT,
            tag: input.tag ?? null,
          },
          auth.user_id
        )
      )
      .select('*')
      .single();
  });

  return taskFromSupabaseJson(row);
}

export interface UpdateTaskInput extends Partial<TaskFormInput> {}

export async function updateTask(task: Task, input: UpdateTaskInput): Promise<Task> {
  const auth = loadAuth();
  if (!auth) throw new Error('未绑定 Tempo 账号');

  const next: Task = {
    ...task,
    title: input.title !== undefined ? input.title.trim() : task.title,
    description: input.description !== undefined ? input.description : task.description,
    priority: input.priority !== undefined ? input.priority : task.priority,
    dueDate: input.dueDate !== undefined ? input.dueDate : task.dueDate,
    isAllDay: input.isAllDay !== undefined ? input.isAllDay : task.isAllDay,
    tag: input.tag !== undefined ? input.tag : task.tag,
    updatedAt: new Date(),
  };

  if (!next.title) {
    throw new Error('任务标题不能为空');
  }

  const row = await withAuthRetry<Record<string, unknown>>(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');

    return supabase
      .from(TABLE_TASKS)
      .update(taskToSupabaseJson(next, auth.user_id))
      .eq('id', task.id)
      .select('*')
      .single();
  });

  return taskFromSupabaseJson(row);
}

export async function toggleTaskComplete(task: Task): Promise<Task> {
  const now = new Date();
  const next: Task = {
    ...task,
    isCompleted: !task.isCompleted,
    completedAt: !task.isCompleted ? now : null,
    updatedAt: now,
  };

  const auth = loadAuth();
  if (!auth) throw new Error('未绑定 Tempo 账号');

  const row = await withAuthRetry<Record<string, unknown>>(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');

    return supabase
      .from(TABLE_TASKS)
      .update(taskToSupabaseJson(next, auth.user_id))
      .eq('id', task.id)
      .select('*')
      .single();
  });

  return taskFromSupabaseJson(row);
}

export async function deleteTask(taskId: string): Promise<void> {
  await withAuthRetryVoid(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');
    return supabase.from(TABLE_TASKS).delete().eq('id', taskId);
  });
}
