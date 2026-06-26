/**
 * 插件逻辑冒烟测试（不依赖思源运行时）
 */
import assert from 'node:assert/strict';

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

function priorityFromValue(value) {
  switch (value) {
    case 1: return 1;
    case 2: return 2;
    case 3: return 3;
    case 4: return 4;
    default: return 0;
  }
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
  };
}

function matchesScope(task, scope, now) {
  switch (scope) {
    case 'pending':
      return !task.isCompleted;
    case 'overdue':
      return (
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

function filterByScope(tasks, scope, now) {
  return tasks.filter((task) => matchesScope(task, scope, now));
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

console.log('verify-plugin: all checks passed');
