import assert from "node:assert/strict";
import test from "node:test";
import {
  type DatabaseTask,
  minuteWindowForDevice,
  occurrenceForLocalDate,
  reminderAtForOccurrence,
  reminderKeyFor,
} from "./reminder_core.ts";

function task(overrides: Partial<DatabaseTask> = {}): DatabaseTask {
  return {
    id: "task-1",
    user_id: "user-1",
    title: "死虫式",
    due_date: "2026-07-10T00:13:00.000Z",
    is_all_day: false,
    is_completed: false,
    recurrence_rule: "FREQ=DAILY;INTERVAL=1",
    recurrence_end: null,
    recurrence_count: 7,
    ...overrides,
  };
}

test("daily count yields only seven calendar occurrences", () => {
  for (let day = 10; day <= 16; day++) {
    assert.equal(
      occurrenceForLocalDate(task(), `2026-07-${day}`, "Asia/Shanghai"),
      true,
    );
  }
  assert.equal(
    occurrenceForLocalDate(task(), "2026-07-17", "Asia/Shanghai"),
    false,
  );
});

test("weekly BYDAY count counts actual occurrences, not weeks", () => {
  const weekly = task({
    due_date: "2026-07-06T01:00:00.000Z",
    recurrence_rule: "FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR;COUNT=4",
    recurrence_count: 4,
  });
  assert.equal(
    occurrenceForLocalDate(weekly, "2026-07-06", "Asia/Shanghai"),
    true,
  );
  assert.equal(
    occurrenceForLocalDate(weekly, "2026-07-13", "Asia/Shanghai"),
    true,
  );
  assert.equal(
    occurrenceForLocalDate(weekly, "2026-07-15", "Asia/Shanghai"),
    false,
  );
});

test("window retries only the immediately previous minute", () => {
  const window = minuteWindowForDevice(
    new Date("2026-07-10T00:15:20Z"),
    "Asia/Shanghai",
  );
  assert.equal(window.startUtc.toISOString(), "2026-07-10T00:13:20.000Z");
  assert.equal(window.endUtc.toISOString(), "2026-07-10T00:15:20.001Z");
});

test("all-day occurrence fires at local 08:00 and key is stable", () => {
  const allDay = task({
    due_date: "2026-07-09T16:00:00.000Z",
    is_all_day: true,
  });
  const at = reminderAtForOccurrence(allDay, "2026-07-10", "Asia/Shanghai");
  assert.equal(at.toISOString(), "2026-07-10T00:00:00.000Z");
  assert.equal(
    reminderKeyFor({
      task: allDay,
      occurrenceDate: "2026-07-10",
      title: allDay.title,
      reminderAtUtc: at,
    }),
    "task-1:2026-07-10:2026-07-10T00:00:00.000Z",
  );
});
