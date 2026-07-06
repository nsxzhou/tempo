import { RRule } from 'rrule';
import { Task } from '../models/task';
import { isOccurrenceCompleted } from '../models/completion';
import { isTaskRecurring, isTaskRecurrenceEnded } from './recurrence_config';
import { startOfDay } from './date_filter';

export interface ExpandedTask {
  seriesTask: Task;
  occurrenceDate: Date;
  displayTask: Task;
}

export interface TaskListItem {
  seriesTask: Task;
  displayTask: Task;
  occurrenceDate?: Date;
  isSeriesEnded: boolean;
}

function toRRuleDtstart(d: Date): Date {
  return new Date(
    Date.UTC(
      d.getFullYear(),
      d.getMonth(),
      d.getDate(),
      d.getHours(),
      d.getMinutes(),
      d.getSeconds()
    )
  );
}

function fromRRuleInstance(d: Date): Date {
  return new Date(
    d.getUTCFullYear(),
    d.getUTCMonth(),
    d.getUTCDate(),
    d.getUTCHours(),
    d.getUTCMinutes(),
    d.getUTCSeconds()
  );
}

function buildRRule(task: Task): RRule | null {
  const ruleStr = task.recurrenceRule;
  if (!ruleStr || !task.dueDate) return null;

  try {
    const parsed = RRule.parseString(ruleStr);
    const dtstart = toRRuleDtstart(task.dueDate);
    const options: Partial<ConstructorParameters<typeof RRule>[0]> = {
      ...parsed,
      dtstart,
    };

    if (task.recurrenceEnd) {
      options.until = toRRuleDtstart(task.recurrenceEnd);
    } else if (task.recurrenceCount != null) {
      options.count = task.recurrenceCount;
    }

    return new RRule(options);
  } catch {
    return null;
  }
}

function effectiveDue(task: Task, day: Date): Date {
  const anchor = task.dueDate!;
  if (task.isAllDay) {
    return startOfDay(day);
  }
  return new Date(
    day.getFullYear(),
    day.getMonth(),
    day.getDate(),
    anchor.getHours(),
    anchor.getMinutes(),
    anchor.getSeconds()
  );
}

export function expandTaskOccurrences(
  task: Task,
  from: Date,
  to: Date,
  completions: Set<string> = new Set()
): ExpandedTask[] {
  if (!isTaskRecurring(task) || !task.dueDate) return [];

  const rule = buildRRule(task);
  if (!rule) return [];

  const fromDay = startOfDay(from);
  const toDay = startOfDay(to);
  const rangeEnd = new Date(toDay);
  rangeEnd.setHours(23, 59, 59, 999);

  const instances = rule.between(toRRuleDtstart(fromDay), toRRuleDtstart(rangeEnd), true);
  const results: ExpandedTask[] = [];

  for (const instance of instances) {
    const local = fromRRuleInstance(instance);
    const day = startOfDay(local);

    if (day.getTime() < fromDay.getTime()) continue;
    if (day.getTime() > toDay.getTime()) break;

    if (task.recurrenceEnd && day.getTime() > startOfDay(task.recurrenceEnd).getTime()) {
      break;
    }

    const due = effectiveDue(task, day);
    const isCompleted = isOccurrenceCompleted(task.id, day, completions);
    results.push({
      seriesTask: task,
      occurrenceDate: day,
      displayTask: {
        ...task,
        dueDate: due,
        isCompleted,
      },
    });

    if (task.recurrenceCount != null && results.length >= task.recurrenceCount) {
      break;
    }
  }

  return results;
}

export function expandTasksInRange(
  tasks: Task[],
  from: Date,
  to: Date,
  completions: Set<string> = new Set()
): ExpandedTask[] {
  const expanded: ExpandedTask[] = [];

  for (const task of tasks) {
    if (isTaskRecurring(task)) {
      expanded.push(...expandTaskOccurrences(task, from, to, completions));
    } else if (task.dueDate) {
      const day = startOfDay(task.dueDate);
      if (day.getTime() >= startOfDay(from).getTime() && day.getTime() <= startOfDay(to).getTime()) {
        expanded.push({
          seriesTask: task,
          occurrenceDate: day,
          displayTask: task,
        });
      }
    }
  }

  return expanded;
}

export function tasksForDate(
  tasks: Task[],
  date: Date,
  completions: Set<string> = new Set()
): Task[] {
  const day = startOfDay(date);
  return expandTasksInRange(tasks, day, day, completions).map(
    (item) => item.displayTask
  );
}

export function hasTasksOnDate(
  tasks: Task[],
  date: Date,
  completions: Set<string> = new Set()
): boolean {
  return tasksForDate(tasks, date, completions).some(
    (task) => !task.isCompleted
  );
}

function itemFromOccurrence(item: ExpandedTask): TaskListItem {
  return {
    seriesTask: item.seriesTask,
    displayTask: item.displayTask,
    occurrenceDate: item.occurrenceDate,
    isSeriesEnded: false,
  };
}

export function buildTaskListItem(
  task: Task,
  completions: Set<string> = new Set(),
  now = new Date()
): TaskListItem {
  if (!isTaskRecurring(task) || !task.dueDate) {
    return {
      seriesTask: task,
      displayTask: task,
      isSeriesEnded: false,
    };
  }

  if (isTaskRecurrenceEnded(task, now)) {
    return {
      seriesTask: task,
      displayTask: {
        ...task,
        dueDate: null,
        isCompleted: false,
        completedAt: null,
      },
      isSeriesEnded: true,
    };
  }

  const today = startOfDay(now);
  const todayOccurrences = expandTaskOccurrences(
    task,
    today,
    today,
    completions
  );
  if (todayOccurrences.length > 0) {
    return itemFromOccurrence(todayOccurrences[0]);
  }

  const futureEnd = new Date(today);
  futureEnd.setFullYear(futureEnd.getFullYear() + 1);
  const futureOccurrences = expandTaskOccurrences(
    task,
    today,
    futureEnd,
    completions
  );
  const nextPending = futureOccurrences.find(
    (item) => !item.displayTask.isCompleted
  );
  if (nextPending) {
    return itemFromOccurrence(nextPending);
  }

  if (task.recurrenceEnd || task.recurrenceCount != null) {
    return {
      seriesTask: task,
      displayTask: {
        ...task,
        dueDate: null,
        isCompleted: false,
        completedAt: null,
      },
      isSeriesEnded: true,
    };
  }

  return {
    seriesTask: task,
    displayTask: task,
    occurrenceDate: startOfDay(task.dueDate),
    isSeriesEnded: false,
  };
}

/** 列表勾选重复任务时，优先打卡今日/下一次 pending occurrence */
export function resolveToggleOccurrenceDate(
  task: Task,
  completions: Set<string>
): Date {
  if (!task.dueDate) return startOfDay(new Date());

  const from = startOfDay(new Date());
  const to = new Date(from);
  to.setFullYear(to.getFullYear() + 1);
  const expanded = expandTaskOccurrences(task, from, to, completions);
  const pending = expanded.find((item) => !item.displayTask.isCompleted);
  if (pending) return pending.occurrenceDate;

  return startOfDay(task.dueDate);
}
