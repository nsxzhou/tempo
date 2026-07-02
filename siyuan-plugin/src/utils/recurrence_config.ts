import { Task } from '../models/task';
import { startOfDay } from './date_filter';

export enum RecurrenceUnit {
  day = 'day',
  week = 'week',
  month = 'month',
}

export interface RecurrenceConfig {
  interval: number;
  unit: RecurrenceUnit;
  weekdays: Set<number>;
  endDate?: Date | null;
  occurrenceCount?: number | null;
}

export const RECURRENCE_NONE: RecurrenceConfig = {
  interval: 0,
  unit: RecurrenceUnit.day,
  weekdays: new Set(),
};

export function hasRecurrence(config: RecurrenceConfig): boolean {
  return config.interval > 0;
}

const WEEKDAY_CODES: Record<number, string> = {
  1: 'MO',
  2: 'TU',
  3: 'WE',
  4: 'TH',
  5: 'FR',
  6: 'SA',
  7: 'SU',
};

const CODE_TO_WEEKDAY: Record<string, number> = {
  MO: 1,
  TU: 2,
  WE: 3,
  TH: 4,
  FR: 5,
  SA: 6,
  SU: 7,
};

export function recurrenceConfigToRRule(config: RecurrenceConfig): string | null {
  if (!hasRecurrence(config)) return null;

  const parts = [`INTERVAL=${config.interval}`];
  switch (config.unit) {
    case RecurrenceUnit.day:
      parts.unshift('FREQ=DAILY');
      break;
    case RecurrenceUnit.week:
      parts.unshift('FREQ=WEEKLY');
      if (config.weekdays.size > 0) {
        const days = [...config.weekdays]
          .sort((a, b) => a - b)
          .map((d) => WEEKDAY_CODES[d])
          .join(',');
        parts.push(`BYDAY=${days}`);
      }
      break;
    case RecurrenceUnit.month:
      parts.unshift('FREQ=MONTHLY');
      break;
  }

  return parts.join(';');
}

export function recurrenceConfigFromRRule(
  rule: string | null | undefined
): RecurrenceConfig | null {
  if (!rule || !rule.trim()) return null;

  const parts: Record<string, string> = {};
  for (const segment of rule.split(';')) {
    const kv = segment.split('=');
    if (kv.length === 2) parts[kv[0].trim()] = kv[1].trim();
  }

  const freq = parts.FREQ;
  if (!freq) return null;

  const interval = Number.parseInt(parts.INTERVAL ?? '1', 10) || 1;
  let unit = RecurrenceUnit.day;
  switch (freq) {
    case 'DAILY':
      unit = RecurrenceUnit.day;
      break;
    case 'WEEKLY':
      unit = RecurrenceUnit.week;
      break;
    case 'MONTHLY':
      unit = RecurrenceUnit.month;
      break;
  }

  const weekdays = new Set<number>();
  const byDay = parts.BYDAY;
  if (byDay) {
    for (const code of byDay.split(',')) {
      const day = CODE_TO_WEEKDAY[code.trim().toUpperCase()];
      if (day) weekdays.add(day);
    }
  }

  return { interval, unit, weekdays };
}

export function recurrenceConfigFromTask(task: Task): RecurrenceConfig {
  const parsed = recurrenceConfigFromRRule(task.recurrenceRule);
  if (!parsed) return { ...RECURRENCE_NONE };

  return {
    ...parsed,
    endDate: task.recurrenceEnd ?? null,
    occurrenceCount: task.recurrenceCount ?? null,
  };
}

export function isTaskRecurring(task: Task): boolean {
  return Boolean(task.recurrenceRule && task.recurrenceRule.trim());
}

/**
 * 重复系列是否已结束（`recurrenceEnd` 当天仍算有效，次日起视为已结束）。
 * 与 Flutter 端 `TaskRecurrenceLifecycle.isRecurrenceEnded` 逻辑一致。
 */
export function isTaskRecurrenceEnded(task: Task, now = new Date()): boolean {
  if (!isTaskRecurring(task) || !task.recurrenceEnd) return false;
  const endDay = startOfDay(task.recurrenceEnd);
  const today = startOfDay(now);
  return today.getTime() > endDay.getTime();
}
