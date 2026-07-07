/**
 * 插件逻辑冒烟测试（不依赖思源运行时）
 */
import assert from 'node:assert/strict';
import rrulePkg from 'rrule';

const { RRule } = rrulePkg;

function isSameDay(a, b) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function isDueInWeekRange(dueDate, now) {
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const weekEnd = new Date(todayStart);
  weekEnd.setDate(weekEnd.getDate() + 7);
  return dueDate >= todayStart && dueDate < weekEnd;
}

function isTaskOverdue({ dueDate, isAllDay, isCompleted, now = new Date() }) {
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

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function isTaskRecurring(task) {
  return Boolean(task.recurrenceRule && task.recurrenceRule.trim());
}

function isTaskRecurrenceEnded(task, now = new Date()) {
  if (!isTaskRecurring(task) || !task.recurrenceEnd) return false;
  return startOfDay(now).getTime() > startOfDay(task.recurrenceEnd).getTime();
}

function completionKey(taskId, day) {
  const y = day.getFullYear();
  const m = String(day.getMonth() + 1).padStart(2, '0');
  const d = String(day.getDate()).padStart(2, '0');
  return `${taskId}:${y}-${m}-${d}`;
}

function isOccurrenceCompleted(taskId, day, completions) {
  return completions.has(completionKey(taskId, day));
}

function toRRuleDtstart(date) {
  return new Date(
    Date.UTC(
      date.getFullYear(),
      date.getMonth(),
      date.getDate(),
      date.getHours(),
      date.getMinutes(),
      date.getSeconds()
    )
  );
}

function fromRRuleInstance(date) {
  return new Date(
    date.getUTCFullYear(),
    date.getUTCMonth(),
    date.getUTCDate(),
    date.getUTCHours(),
    date.getUTCMinutes(),
    date.getUTCSeconds()
  );
}

function buildRRule(task) {
  if (!task.recurrenceRule || !task.dueDate) return null;

  const parsed = RRule.parseString(task.recurrenceRule);
  const options = {
    ...parsed,
    dtstart: toRRuleDtstart(task.dueDate),
  };
  if (task.recurrenceEnd) {
    options.until = toRRuleDtstart(task.recurrenceEnd);
  } else if (task.recurrenceCount != null) {
    options.count = task.recurrenceCount;
  }
  return new RRule(options);
}

function effectiveDue(task, day) {
  const anchor = task.dueDate;
  if (task.isAllDay) return startOfDay(day);
  return new Date(
    day.getFullYear(),
    day.getMonth(),
    day.getDate(),
    anchor.getHours(),
    anchor.getMinutes(),
    anchor.getSeconds()
  );
}

function expandTaskOccurrences(task, from, to, completions = new Set()) {
  if (!isTaskRecurring(task) || !task.dueDate) return [];

  const rule = buildRRule(task);
  if (!rule) return [];

  const fromDay = startOfDay(from);
  const toDay = startOfDay(to);
  const rangeEnd = new Date(toDay);
  rangeEnd.setHours(23, 59, 59, 999);
  const instances = rule.between(toRRuleDtstart(fromDay), toRRuleDtstart(rangeEnd), true);
  const results = [];

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
  }

  return results;
}

function buildTaskListItem(task, completions = new Set(), now = new Date()) {
  if (!isTaskRecurring(task) || !task.dueDate) {
    return { seriesTask: task, displayTask: task, isSeriesEnded: false };
  }

  if (isTaskRecurrenceEnded(task, now)) {
    return {
      seriesTask: task,
      displayTask: {
        ...task,
        dueDate: null,
        isCompleted: false,
      },
      isSeriesEnded: true,
    };
  }

  const today = startOfDay(now);
  const todayOccurrences = expandTaskOccurrences(task, today, today, completions);
  if (todayOccurrences.length > 0) {
    const item = todayOccurrences[0];
    return {
      seriesTask: item.seriesTask,
      displayTask: item.displayTask,
      occurrenceDate: item.occurrenceDate,
      isSeriesEnded: false,
    };
  }

  const futureEnd = new Date(today);
  futureEnd.setFullYear(futureEnd.getFullYear() + 1);
  const futureOccurrences = expandTaskOccurrences(task, today, futureEnd, completions);
  const nextPending = futureOccurrences.find((item) => !item.displayTask.isCompleted);
  if (nextPending) {
    return {
      seriesTask: nextPending.seriesTask,
      displayTask: nextPending.displayTask,
      occurrenceDate: nextPending.occurrenceDate,
      isSeriesEnded: false,
    };
  }

  if (task.recurrenceEnd || task.recurrenceCount != null) {
    return {
      seriesTask: task,
      displayTask: {
        ...task,
        dueDate: null,
        isCompleted: false,
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

function priorityFromValue(value) {
  switch (value) {
    case 1: return 1;
    case 2: return 2;
    case 3: return 3;
    case 4: return 4;
    default: return 0;
  }
}

function isInvalidRefreshToken(status, body) {
  if (![400, 401, 403].includes(status)) return false;
  const text = body.toLowerCase();
  return (
    text.includes('refresh') ||
    text.includes('invalid') ||
    text.includes('expired') ||
    text.includes('not found')
  );
}

function taskFromSupabaseJson(json) {
  return {
    id: json.id,
    title: json.title,
    priority: priorityFromValue(json.priority ?? 0),
    tag: json.tag ?? null,
    dueDate: json.due_date ? new Date(json.due_date) : null,
    isAllDay: json.is_all_day ?? false,
    isCompleted: json.is_completed ?? false,
    recurrenceRule: json.recurrence_rule ?? null,
    recurrenceEnd: json.recurrence_end ? new Date(json.recurrence_end) : null,
    recurrenceCount: json.recurrence_count ?? null,
  };
}

function matchesScope(item, scope, now) {
  const task = item.displayTask;
  switch (scope) {
    case 'pending':
      return !item.isSeriesEnded && !task.isCompleted;
    case 'overdue':
      return (
        !item.isSeriesEnded &&
        task.dueDate &&
        isTaskOverdue({
          dueDate: task.dueDate,
          isAllDay: task.isAllDay,
          isCompleted: task.isCompleted,
          now,
        })
      );
    case 'week':
      return (
        !item.isSeriesEnded &&
        !task.isCompleted &&
        task.dueDate &&
        isDueInWeekRange(task.dueDate, now)
      );
    case 'all':
      return true;
    default:
      throw new Error(`Unknown scope: ${scope}`);
  }
}

function filterByScope(tasks, scope, now, completions = new Set()) {
  return tasks
    .map((task) => buildTaskListItem(task, completions, now))
    .filter((item) => matchesScope(item, scope, now))
    .map((item) => item.displayTask);
}

{
  const now = new Date(2026, 5, 22, 10, 0, 0);
  const today = new Date(2026, 5, 22, 15, 0, 0);
  assert.equal(isSameDay(now, today), true);
  assert.equal(isDueInWeekRange(today, now), true);

  const overdue = new Date(2026, 5, 20, 12, 0, 0);
  assert.equal(
    isTaskOverdue({
      dueDate: overdue,
      isAllDay: true,
      isCompleted: false,
      now,
    }),
    true
  );
}

function isDueOnDate(dueDate, date) {
  return isSameDay(dueDate, date);
}

{
  const due = new Date(2026, 5, 22, 15, 0, 0);
  const day = new Date(2026, 5, 22, 9, 0, 0);
  assert.equal(isDueOnDate(due, day), true);
}

{
  const task = taskFromSupabaseJson({
    id: 'task-1',
    title: '测试任务',
    priority: 2,
    tag: 'work',
    is_completed: false,
  });
  assert.equal(task.title, '测试任务');
  assert.equal(task.priority, 2);
  assert.equal(task.tag, 'work');
}

{
  const now = new Date(2026, 5, 22, 10, 0, 0);
  const tasks = [
    taskFromSupabaseJson({
      id: 'task-active',
      title: '未完成',
      is_completed: false,
      due_date: '2026-06-22T15:00:00.000Z',
    }),
    taskFromSupabaseJson({
      id: 'task-done',
      title: '已完成',
      is_completed: true,
      due_date: '2026-06-22T15:00:00.000Z',
    }),
    taskFromSupabaseJson({
      id: 'task-overdue',
      title: '逾期',
      is_completed: false,
      due_date: '2026-06-20T12:00:00.000Z',
    }),
  ];

  assert.deepEqual(
    filterByScope(tasks, 'pending', now).map((task) => task.id),
    ['task-active', 'task-overdue']
  );
  assert.deepEqual(
    filterByScope(tasks, 'all', now).map((task) => task.id),
    ['task-active', 'task-done', 'task-overdue']
  );
  assert.deepEqual(
    filterByScope(tasks, 'overdue', now).map((task) => task.id),
    ['task-overdue']
  );
}

{
  const now = new Date(2026, 6, 2, 10, 0, 0);
  const recurring = taskFromSupabaseJson({
    id: 'task-daily',
    title: '死虫式',
    is_completed: false,
    is_all_day: true,
    due_date: '2026-07-01T12:00:00.000Z',
    recurrence_rule: 'FREQ=DAILY;INTERVAL=1',
  });

  assert.deepEqual(
    filterByScope([recurring], 'overdue', now).map((task) => task.id),
    []
  );

  const pending = filterByScope([recurring], 'pending', now);
  assert.deepEqual(pending.map((task) => task.id), ['task-daily']);
  assert.equal(isSameDay(pending[0].dueDate, now), true);
}

{
  const now = new Date(2026, 6, 2, 10, 0, 0);
  const recurring = taskFromSupabaseJson({
    id: 'task-daily-done',
    title: '已打卡',
    is_completed: false,
    is_all_day: true,
    due_date: '2026-07-01T12:00:00.000Z',
    recurrence_rule: 'FREQ=DAILY;INTERVAL=1',
  });
  const completions = new Set([completionKey(recurring.id, startOfDay(now))]);

  assert.deepEqual(
    filterByScope([recurring], 'pending', now, completions).map((task) => task.id),
    []
  );
}

{
  assert.equal(
    isInvalidRefreshToken(400, '{"error":"invalid refresh token"}'),
    true
  );
  assert.equal(
    isInvalidRefreshToken(401, '{"error":"refresh token expired"}'),
    true
  );
  assert.equal(
    isInvalidRefreshToken(500, '{"error":"temporary upstream failure"}'),
    false
  );
  assert.equal(
    isInvalidRefreshToken(0, 'network request failed'),
    false
  );
}

console.log('verify-plugin: all checks passed');
