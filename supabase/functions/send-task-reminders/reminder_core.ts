export type DatabaseTask = {
  id: string;
  user_id: string;
  title: string;
  due_date: string | null;
  is_all_day: boolean;
  is_completed: boolean;
  recurrence_rule: string | null;
  recurrence_end: string | null;
  recurrence_count: number | null;
};

export type ReminderCandidate = {
  task: DatabaseTask;
  occurrenceDate: string | null;
  title: string;
  reminderAtUtc: Date;
};

export function minuteWindowForDevice(now: Date, timezone: string) {
  const local = localParts(now, timezone);
  return {
    local,
    localDate: formatLocalDate(local.year, local.month, local.day),
    startUtc: new Date(now.getTime() - 120_000),
    endUtc: new Date(now.getTime() + 1),
    timezone,
  };
}

export function reminderAtForTask(task: DatabaseTask, timezone: string): Date {
  const due = new Date(task.due_date!);
  const local = localParts(due, timezone);
  if (task.is_all_day) {
    return localDateToUtc(
      local.year,
      local.month,
      local.day,
      8,
      0,
      0,
      timezone,
    );
  }
  return due;
}

export function reminderAtForOccurrence(
  task: DatabaseTask,
  localDate: string,
  timezone: string,
  overrideDue?: string | null,
): Date {
  if (overrideDue) return new Date(overrideDue);
  const [year, month, day] = localDate.split("-").map(Number);
  if (task.is_all_day) {
    return localDateToUtc(year, month, day, 8, 0, 0, timezone);
  }
  const dueLocal = localParts(new Date(task.due_date!), timezone);
  return localDateToUtc(
    year,
    month,
    day,
    dueLocal.hour,
    dueLocal.minute,
    dueLocal.second,
    timezone,
  );
}

export function occurrenceForLocalDate(
  task: DatabaseTask,
  localDate: string,
  timezone: string,
): boolean {
  const dueLocal = localParts(new Date(task.due_date!), timezone);
  const startDate = formatLocalDate(
    dueLocal.year,
    dueLocal.month,
    dueLocal.day,
  );
  if (localDate < startDate) return false;
  if (
    task.recurrence_end &&
    localDate > localDateFromTimestamp(task.recurrence_end, timezone)
  ) {
    return false;
  }

  const rule = parseRrule(task.recurrence_rule ?? "");
  const until = rule.get("UNTIL");
  if (until && localDate > normalizeUntilDate(until, timezone)) return false;
  if (!matchesRuleDate(startDate, localDate, rule)) return false;

  const count = task.recurrence_count ?? numberOrNull(rule.get("COUNT"));
  if (count != null && occurrenceOrdinal(startDate, localDate, rule) >= count) {
    return false;
  }
  return true;
}

export function reminderKeyFor(candidate: ReminderCandidate): string {
  return `${candidate.task.id}:${candidate.occurrenceDate ?? "single"}:${candidate.reminderAtUtc.toISOString()}`;
}

export function isInWindow(date: Date, start: Date, end: Date): boolean {
  return date.getTime() >= start.getTime() && date.getTime() < end.getTime();
}

export function localParts(date: Date, timezone: string) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).formatToParts(date);
  const part = (type: string) =>
    Number(parts.find((p) => p.type === type)?.value);
  return {
    year: part("year"),
    month: part("month"),
    day: part("day"),
    hour: part("hour"),
    minute: part("minute"),
    second: part("second"),
  };
}

export function localDateToUtc(
  year: number,
  month: number,
  day: number,
  hour: number,
  minute: number,
  second: number,
  timezone: string,
): Date {
  const utcGuess = Date.UTC(year, month - 1, day, hour, minute, second);
  const offset = timezoneOffsetMillis(new Date(utcGuess), timezone);
  return new Date(utcGuess - offset);
}

export function formatLocalDate(
  year: number,
  month: number,
  day: number,
): string {
  return `${year.toString().padStart(4, "0")}-${month.toString().padStart(2, "0")}-${day.toString().padStart(2, "0")}`;
}

function timezoneOffsetMillis(date: Date, timezone: string): number {
  const parts = localParts(date, timezone);
  const localAsUtc = Date.UTC(
    parts.year,
    parts.month - 1,
    parts.day,
    parts.hour,
    parts.minute,
    parts.second,
  );
  return localAsUtc - date.getTime();
}

function parseRrule(rrule: string): Map<string, string> {
  const map = new Map<string, string>();
  for (const part of rrule.split(";")) {
    const [key, value] = part.split("=");
    if (key && value) map.set(key, value);
  }
  return map;
}

function matchesRuleDate(
  startDate: string,
  localDate: string,
  rule: Map<string, string>,
): boolean {
  const interval = Number(rule.get("INTERVAL") ?? "1");
  if (!Number.isFinite(interval) || interval <= 0) return false;
  const days = daysBetween(startDate, localDate);
  const freq = rule.get("FREQ");
  if (freq === "DAILY") return days % interval === 0;
  if (freq === "WEEKLY") {
    if (Math.floor(days / 7) % interval !== 0) return false;
    const weekdays = (
      rule.get("BYDAY") ?? weekdayTokenForDate(startDate)
    ).split(",");
    return weekdays.includes(weekdayTokenForDate(localDate));
  }
  if (freq === "MONTHLY") {
    const [sy, sm, sd] = startDate.split("-").map(Number);
    const [y, m, d] = localDate.split("-").map(Number);
    const monthDelta = (y - sy) * 12 + (m - sm);
    const monthDays = (rule.get("BYMONTHDAY") ?? String(sd))
      .split(",")
      .map(Number);
    return (
      monthDelta >= 0 && monthDelta % interval === 0 && monthDays.includes(d)
    );
  }
  return false;
}

function occurrenceOrdinal(
  startDate: string,
  localDate: string,
  rule: Map<string, string>,
): number {
  let ordinal = 0;
  for (
    let cursor = startDate;
    cursor < localDate;
    cursor = addDays(cursor, 1)
  ) {
    if (matchesRuleDate(startDate, cursor, rule)) ordinal++;
  }
  return ordinal;
}

function normalizeUntilDate(until: string, timezone: string): string {
  if (/^\d{8}/.test(until)) {
    const compact = until.slice(0, 8);
    return `${compact.slice(0, 4)}-${compact.slice(4, 6)}-${compact.slice(6, 8)}`;
  }
  return localDateFromTimestamp(until, timezone);
}

function localDateFromTimestamp(value: string, timezone: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value.slice(0, 10);
  const local = localParts(date, timezone);
  return formatLocalDate(local.year, local.month, local.day);
}

function numberOrNull(value?: string): number | null {
  if (value == null) return null;
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
}

function addDays(localDate: string, amount: number): string {
  const [year, month, day] = localDate.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day + amount));
  return formatLocalDate(
    date.getUTCFullYear(),
    date.getUTCMonth() + 1,
    date.getUTCDate(),
  );
}

function daysBetween(startDate: string, endDate: string): number {
  const [sy, sm, sd] = startDate.split("-").map(Number);
  const [ey, em, ed] = endDate.split("-").map(Number);
  return Math.floor(
    (Date.UTC(ey, em - 1, ed) - Date.UTC(sy, sm - 1, sd)) / 86_400_000,
  );
}

function weekdayTokenForDate(localDate: string): string {
  const [year, month, day] = localDate.split("-").map(Number);
  return ["SU", "MO", "TU", "WE", "TH", "FR", "SA"][
    new Date(Date.UTC(year, month - 1, day)).getUTCDay()
  ];
}
