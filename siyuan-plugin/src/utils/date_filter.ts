export function isDueOnDate(dueDate: Date, date: Date): boolean {
  return isSameDay(dueDate, date);
}

export interface MonthCell {
  date: Date;
  isOtherMonth: boolean;
}

export function getMonthGrid(selectedDate: Date): MonthCell[] {
  const firstDay = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1);
  const leadingEmpty = (firstDay.getDay() + 6) % 7;
  const daysInMonth = new Date(
    selectedDate.getFullYear(),
    selectedDate.getMonth() + 1,
    0
  ).getDate();

  const cells: MonthCell[] = [];

  for (let i = 0; i < leadingEmpty; i += 1) {
    const d = new Date(firstDay);
    d.setDate(firstDay.getDate() - (leadingEmpty - i));
    cells.push({ date: d, isOtherMonth: true });
  }

  for (let day = 1; day <= daysInMonth; day += 1) {
    cells.push({
      date: new Date(selectedDate.getFullYear(), selectedDate.getMonth(), day),
      isOtherMonth: false,
    });
  }

  while (cells.length < 42) {
    const last = cells[cells.length - 1].date;
    const next = new Date(last);
    next.setDate(last.getDate() + 1);
    cells.push({ date: next, isOtherMonth: true });
  }

  return cells;
}

export function getWeekDates(selectedDate: Date): Date[] {
  const monday = getMonday(selectedDate);
  return Array.from({ length: 7 }, (_, index) => {
    const day = new Date(monday);
    day.setDate(monday.getDate() + index);
    return day;
  });
}

export function getMonday(date: Date): Date {
  const weekday = date.getDay() === 0 ? 7 : date.getDay();
  const monday = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  monday.setDate(monday.getDate() - (weekday - 1));
  return monday;
}

export function weekdayLabel(weekday: number): string {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[(weekday - 1) % 7];
}

export function cnWeekday(date: Date): string {
  const weekday = date.getDay() === 0 ? 7 : date.getDay();
  return weekdayLabel(weekday);
}

export function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export function priorityDotColor(priority: number): string {
  switch (priority) {
    case 1:
      return 'var(--tempo-p0)';
    case 2:
      return 'var(--tempo-p1)';
    case 3:
      return 'var(--tempo-p2)';
    case 4:
      return 'var(--tempo-p3)';
    default:
      return 'var(--tempo-fg-faint)';
  }
}

export function formatMonthLabel(date: Date): string {
  return `${date.getFullYear()} 年 ${date.getMonth() + 1} 月`;
}

export function formatDayLabel(date: Date): string {
  return `${date.getMonth() + 1} 月 ${date.getDate()} 日`;
}

export function formatMonthYearShort(date: Date): string {
  return `${date.getMonth() + 1}/${date.getFullYear()}`;
}

export function formatTimeShort(date: Date): string {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function getWeekNumber(date: Date, now = new Date()): number {
  const start = new Date(now.getFullYear(), 0, 1);
  const diffDays = Math.floor(
    (startOfDay(date).getTime() - startOfDay(start).getTime()) / 86400000
  );
  return Math.floor(diffDays / 7) + 1;
}

export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

export function isDueInWeekRange(dueDate: Date, now: Date): boolean {
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const weekEnd = new Date(todayStart);
  weekEnd.setDate(weekEnd.getDate() + 7);
  return dueDate >= todayStart && dueDate < weekEnd;
}

export function isTaskOverdue(options: {
  dueDate: Date;
  isAllDay: boolean;
  isCompleted: boolean;
  now?: Date;
}): boolean {
  const { dueDate, isAllDay, isCompleted, now = new Date() } = options;
  if (isCompleted) return false;

  if (isAllDay) {
    const endOfDay = new Date(
      dueDate.getFullYear(),
      dueDate.getMonth(),
      dueDate.getDate(),
      23,
      59,
      59
    );
    return now > endOfDay;
  }

  return dueDate < now;
}

function pad(value: number): string {
  return value.toString().padStart(2, '0');
}

export function formatTaskDueLabel(options: {
  dueDate: Date;
  isAllDay: boolean;
  now?: Date;
}): string {
  const { dueDate, isAllDay, now = new Date() } = options;

  if (isAllDay) {
    if (isSameDay(dueDate, now)) return '今天';
    return `${dueDate.getMonth() + 1}月${dueDate.getDate()}日`;
  }

  if (isSameDay(dueDate, now)) {
    return `今天 ${pad(dueDate.getHours())}:${pad(dueDate.getMinutes())}`;
  }

  return `${dueDate.getMonth() + 1}月${dueDate.getDate()}日 ${pad(dueDate.getHours())}:${pad(dueDate.getMinutes())}`;
}

export function formatHeaderDate(now = new Date()): string {
  const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
  return `${now.getMonth() + 1} 月 ${now.getDate()} 日 · ${weekdays[now.getDay()]}`;
}

export function toDateInputValue(date: Date): string {
  const year = date.getFullYear();
  const month = pad(date.getMonth() + 1);
  const day = pad(date.getDate());
  return `${year}-${month}-${day}`;
}

export function toTimeInputValue(date: Date): string {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function parseDueDate(dateValue: string, timeValue: string, isAllDay: boolean): Date | null {
  if (!dateValue) return null;
  const [year, month, day] = dateValue.split('-').map(Number);
  if (isAllDay) {
    return new Date(year, month - 1, day, 12, 0, 0);
  }
  const [hour, minute] = timeValue.split(':').map(Number);
  return new Date(year, month - 1, day, hour || 0, minute || 0, 0);
}
