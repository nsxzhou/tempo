export enum TaskPriority {
  none = 0,
  p0 = 1,
  p1 = 2,
  p2 = 3,
  p3 = 4,
}

export interface Task {
  id: string;
  listId: string;
  title: string;
  description?: string | null;
  priority: TaskPriority;
  dueDate?: Date | null;
  isAllDay: boolean;
  isCompleted: boolean;
  completedAt?: Date | null;
  siyuanBlockId?: string | null;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
  creationSource: string;
  tag?: string | null;
  recurrenceRule?: string | null;
  recurrenceEnd?: Date | null;
  recurrenceCount?: number | null;
  durationMin?: number | null;
}

export function priorityFromValue(value: number | null | undefined): TaskPriority {
  switch (value) {
    case TaskPriority.p0:
      return TaskPriority.p0;
    case TaskPriority.p1:
      return TaskPriority.p1;
    case TaskPriority.p2:
      return TaskPriority.p2;
    case TaskPriority.p3:
      return TaskPriority.p3;
    default:
      return TaskPriority.none;
  }
}

export function priorityLabel(priority: TaskPriority): string | null {
  switch (priority) {
    case TaskPriority.p0:
      return '紧急';
    case TaskPriority.p1:
      return '高';
    case TaskPriority.p2:
      return '中';
    case TaskPriority.p3:
      return '低';
    default:
      return null;
  }
}

export function taskFromSupabaseJson(json: Record<string, unknown>): Task {
  return {
    id: json.id as string,
    listId: json.list_id as string,
    title: json.title as string,
    description: (json.description as string | null | undefined) ?? null,
    priority: priorityFromValue(json.priority as number | null | undefined),
    dueDate: json.due_date
      ? new Date(json.due_date as string)
      : null,
    isAllDay: (json.is_all_day as boolean | undefined) ?? false,
    isCompleted: (json.is_completed as boolean | undefined) ?? false,
    completedAt: json.completed_at
      ? new Date(json.completed_at as string)
      : null,
    siyuanBlockId: (json.siyuan_block_id as string | null | undefined) ?? null,
    sortOrder: (json.sort_order as number | undefined) ?? 0,
    createdAt: new Date(json.created_at as string),
    updatedAt: new Date(json.updated_at as string),
    creationSource: (json.creation_source as string | undefined) ?? 'text',
    tag: (json.tag as string | null | undefined) ?? null,
    recurrenceRule: (json.recurrence_rule as string | null | undefined) ?? null,
    recurrenceEnd: json.recurrence_end
      ? new Date(json.recurrence_end as string)
      : null,
    recurrenceCount: (json.recurrence_count as number | null | undefined) ?? null,
    durationMin: (json.duration_min as number | null | undefined) ?? null,
  };
}

export function taskToSupabaseJson(
  task: Partial<Task> & { title?: string },
  userId: string
): Record<string, unknown> {
  const payload: Record<string, unknown> = {
    user_id: userId,
  };

  if (task.id) payload.id = task.id;
  if (task.listId) payload.list_id = task.listId;
  if (task.title !== undefined) payload.title = task.title;
  if (task.description !== undefined) payload.description = task.description;
  if (task.priority !== undefined) payload.priority = task.priority;
  if (task.dueDate !== undefined) {
    payload.due_date = task.dueDate ? task.dueDate.toISOString() : null;
  }
  if (task.isAllDay !== undefined) payload.is_all_day = task.isAllDay;
  if (task.isCompleted !== undefined) payload.is_completed = task.isCompleted;
  if (task.completedAt !== undefined) {
    payload.completed_at = task.completedAt
      ? task.completedAt.toISOString()
      : null;
  }
  if (task.siyuanBlockId !== undefined) {
    payload.siyuan_block_id = task.siyuanBlockId;
  }
  if (task.sortOrder !== undefined) payload.sort_order = task.sortOrder;
  if (task.creationSource !== undefined) {
    payload.creation_source = task.creationSource;
  }
  if (task.tag !== undefined) payload.tag = task.tag;
  if (task.recurrenceRule !== undefined) {
    payload.recurrence_rule = task.recurrenceRule;
  }
  if (task.recurrenceEnd !== undefined) {
    payload.recurrence_end = task.recurrenceEnd
      ? task.recurrenceEnd.toISOString()
      : null;
  }
  if (task.recurrenceCount !== undefined) {
    payload.recurrence_count = task.recurrenceCount;
  }
  if (task.durationMin !== undefined) payload.duration_min = task.durationMin;

  return payload;
}
