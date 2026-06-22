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
    isCompleted: json.is_completed ?? false,
  };
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

console.log('verify-plugin: all checks passed');
