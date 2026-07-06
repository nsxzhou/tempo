import { Task } from '../models/task';
import { isDueInWeekRange, isTaskOverdue } from '../utils/date_filter';
import {
  createTask,
  deleteTask,
  fetchCompletionsForTasks,
  fetchTasks,
  toggleTaskComplete,
  updateTask,
  type CreateTaskInput,
  type TaskFormInput,
  type UpdateTaskInput,
} from './task_repository';
import { isTaskRecurring } from '../utils/recurrence_config';
import {
  buildTaskListItem,
  resolveToggleOccurrenceDate,
  type TaskListItem,
} from '../utils/rrule_expand';
import { completionKey } from '../models/completion';

export type TaskScope = 'pending' | 'overdue' | 'week' | 'all';

type Listener = () => void;

export class TaskStore {
  private tasks: Task[] = [];
  private completions = new Set<string>();
  private listeners = new Set<Listener>();
  private loading = false;
  private error: string | null = null;

  scope: TaskScope = 'pending';

  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private notify(): void {
    for (const listener of this.listeners) {
      listener();
    }
  }

  getTasks(): Task[] {
    return this.tasks;
  }

  getCompletions(): Set<string> {
    return this.completions;
  }

  getLoading(): boolean {
    return this.loading;
  }

  getError(): string | null {
    return this.error;
  }

  setScope(scope: TaskScope): void {
    this.scope = scope;
    this.notify();
  }

  async init(): Promise<void> {
    await this.refresh();
  }

  async refresh(): Promise<void> {
    this.loading = true;
    this.error = null;
    this.notify();

    try {
      this.tasks = await fetchTasks();
      const recurringIds = this.tasks
        .filter((task) => isTaskRecurring(task))
        .map((task) => task.id);
      this.completions = await fetchCompletionsForTasks(recurringIds);
    } catch (error) {
      this.error = error instanceof Error ? error.message : String(error);
    } finally {
      this.loading = false;
      this.notify();
    }
  }

  destroy(): void {
    this.listeners.clear();
  }

  private getListItems(now: Date): TaskListItem[] {
    return this.tasks.map((task) =>
      buildTaskListItem(task, this.completions, now)
    );
  }

  getFilteredTasks(): { active: TaskListItem[]; completed: TaskListItem[] } {
    const now = new Date();
    let items = this.getListItems(now);

    switch (this.scope) {
      case 'pending':
        items = items.filter(
          (item) => !item.isSeriesEnded && !item.displayTask.isCompleted
        );
        break;
      case 'week':
        items = items.filter(
          (item) =>
            !item.isSeriesEnded &&
            !item.displayTask.isCompleted &&
            item.displayTask.dueDate &&
            isDueInWeekRange(item.displayTask.dueDate, now)
        );
        break;
      case 'overdue':
        items = items.filter(
          (item) =>
            !item.isSeriesEnded &&
            item.displayTask.dueDate &&
            isTaskOverdue({
              dueDate: item.displayTask.dueDate,
              isAllDay: item.displayTask.isAllDay,
              isCompleted: item.displayTask.isCompleted,
              now,
            })
        );
        break;
      case 'all':
        break;
    }

    const active = items.filter((item) => !item.displayTask.isCompleted);
    const completed = items.filter((item) => item.displayTask.isCompleted);
    return { active, completed };
  }

  getStats(): {
    pending: number;
    overdue: number;
    week: number;
    all: number;
  } {
    const now = new Date();
    const items = this.getListItems(now);
    const pending = items.filter(
      (item) => !item.isSeriesEnded && !item.displayTask.isCompleted
    ).length;
    const overdue = items.filter(
      (item) =>
        !item.isSeriesEnded &&
        item.displayTask.dueDate &&
        isTaskOverdue({
          dueDate: item.displayTask.dueDate,
          isAllDay: item.displayTask.isAllDay,
          isCompleted: item.displayTask.isCompleted,
          now,
        })
    ).length;
    const weekCount = items.filter(
      (item) =>
        !item.isSeriesEnded &&
        !item.displayTask.isCompleted &&
        item.displayTask.dueDate &&
        isDueInWeekRange(item.displayTask.dueDate, now)
    ).length;

    return {
      pending,
      overdue,
      week: weekCount,
      all: items.length,
    };
  }

  async addTask(input: TaskFormInput): Promise<void> {
    const created = await createTask(input);
    this.tasks = [created, ...this.tasks.filter((task) => task.id !== created.id)];
    this.notify();
  }

  async editTask(task: Task, input: UpdateTaskInput): Promise<void> {
    const updated = await updateTask(task, input);
    this.tasks = this.tasks.map((item) => (item.id === updated.id ? updated : item));
    this.notify();
  }

  async toggleComplete(task: Task, occurrenceDate?: Date): Promise<void> {
    if (isTaskRecurring(task)) {
      const resolvedDate =
        occurrenceDate ?? resolveToggleOccurrenceDate(task, this.completions);
      const key = completionKey(task.id, resolvedDate);
      const wasCompleted = this.completions.has(key);

      await toggleTaskComplete(task, {
        occurrenceDate: resolvedDate,
        completions: this.completions,
      });

      if (wasCompleted) {
        this.completions.delete(key);
      } else {
        this.completions.add(key);
      }
      this.notify();
      return;
    }

    const updated = await toggleTaskComplete(task);
    this.tasks = this.tasks.map((item) =>
      item.id === updated.id ? updated : item
    );
    this.notify();
  }

  async removeTask(taskId: string): Promise<void> {
    await deleteTask(taskId);
    this.tasks = this.tasks.filter((task) => task.id !== taskId);
    this.notify();
  }
}
