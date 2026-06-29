export interface TaskCompletion {
  taskId: string;
  occurrenceDate: Date;
  completedAt: Date;
}

export function completionKey(taskId: string, day: Date): string {
  const y = day.getFullYear();
  const m = String(day.getMonth() + 1).padStart(2, '0');
  const d = String(day.getDate()).padStart(2, '0');
  return `${taskId}:${y}-${m}-${d}`;
}

export function completionSetFromRows(
  rows: Record<string, unknown>[]
): Set<string> {
  const set = new Set<string>();
  for (const row of rows) {
    const taskId = row.task_id as string;
    const dateStr = row.occurrence_date as string;
    const [y, m, d] = dateStr.split('-').map(Number);
    set.add(completionKey(taskId, new Date(y, m - 1, d)));
  }
  return set;
}

export function isOccurrenceCompleted(
  taskId: string,
  day: Date,
  completions: Set<string>
): boolean {
  return completions.has(completionKey(taskId, day));
}
