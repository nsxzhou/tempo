import { SOURCE_TEXT, TABLE_TASKS, TABLE_TASK_COMPLETIONS } from '../constants';
import {
  Task,
  taskFromSupabaseJson,
  taskToSupabaseJson,
  TaskPriority,
} from '../models/task';
import { completionSetFromRows, isOccurrenceCompleted } from '../models/completion';
import { getClient, withAuthRetry, withAuthRetryVoid } from '../api';
import { getOrCreateInboxListId } from './list_repository';
import { loadAuth } from '../storage';
import { isTaskRecurring } from '../utils/recurrence_config';
import { startOfDay } from '../utils/date_filter';

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

function dateOnlyString(day: Date): string {
  const y = day.getFullYear();
  const m = String(day.getMonth() + 1).padStart(2, '0');
  const d = String(day.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export async function fetchCompletionsForTasks(
  taskIds: string[]
): Promise<Set<string>> {
  if (taskIds.length === 0) return new Set();

  const auth = loadAuth();
  if (!auth) throw new Error('未绑定 Tempo 账号');

  const rows = await withAuthRetry<Record<string, unknown>[]>(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');

    return supabase
      .from(TABLE_TASK_COMPLETIONS)
      .select('task_id, occurrence_date')
      .in('task_id', taskIds);
  });

  return completionSetFromRows(rows);
}

async function upsertCompletion(
  taskId: string,
  occurrenceDate: Date
): Promise<void> {
  const auth = loadAuth();
  if (!auth) throw new Error('未绑定 Tempo 账号');

  await withAuthRetryVoid(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');

    return supabase.from(TABLE_TASK_COMPLETIONS).upsert({
      task_id: taskId,
      occurrence_date: dateOnlyString(occurrenceDate),
      completed_at: new Date().toISOString(),
    });
  });
}

async function deleteCompletion(
  taskId: string,
  occurrenceDate: Date
): Promise<void> {
  await withAuthRetryVoid(async () => {
    const supabase = getClient();
    if (!supabase) throw new Error('未绑定 Tempo 账号');

    return supabase
      .from(TABLE_TASK_COMPLETIONS)
      .delete()
      .eq('task_id', taskId)
      .eq('occurrence_date', dateOnlyString(occurrenceDate));
  });
}

export interface TaskFormInput {
  title: string;
  description?: string | null;
  priority?: TaskPriority;
  dueDate?: Date | null;
  isAllDay?: boolean;
  tag?: string | null;
  recurrenceRule?: string | null;
  recurrenceEnd?: Date | null;
  recurrenceCount?: number | null;
  durationMin?: number | null;
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
            recurrenceRule: input.recurrenceRule ?? null,
            recurrenceEnd: input.recurrenceEnd ?? null,
            recurrenceCount: input.recurrenceCount ?? null,
            durationMin: input.durationMin ?? null,
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
    recurrenceRule:
      input.recurrenceRule !== undefined ? input.recurrenceRule : task.recurrenceRule,
    recurrenceEnd:
      input.recurrenceEnd !== undefined ? input.recurrenceEnd : task.recurrenceEnd,
    recurrenceCount:
      input.recurrenceCount !== undefined
        ? input.recurrenceCount
        : task.recurrenceCount,
    durationMin:
      input.durationMin !== undefined ? input.durationMin : task.durationMin,
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

export async function toggleTaskComplete(
  task: Task,
  options?: { occurrenceDate?: Date; completions?: Set<string> }
): Promise<Task> {
  if (isTaskRecurring(task) && task.dueDate) {
    const day = startOfDay(
      options?.occurrenceDate ?? task.dueDate
    );
    const completions = options?.completions ?? new Set<string>();
    const completed = isOccurrenceCompleted(task.id, day, completions);

    if (completed) {
      await deleteCompletion(task.id, day);
    } else {
      await upsertCompletion(task.id, day);
    }

    return task;
  }

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
