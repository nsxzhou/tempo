import { Task } from '../models/task';
import { isDueInWeekRange, isTaskOverdue, startOfDay } from '../utils/date_filter';
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
import { isTaskRecurring, isTaskRecurrenceEnded } from '../utils/recurrence_config';
import { resolveToggleOccurrenceDate } from '../utils/rrule_expand';
import { completionKey, isOccurrenceCompleted } from '../models/completion';

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

  /**
   * 判断任务是否"事实上已完成"。
   * 非重复任务：直接看 isCompleted。
   * 重复任务：isCompleted 始终为 false，需检查今日 occurrence 是否已打卡。
   */
  private isEffectivelyCompleted(task: Task, now: Date): boolean {
    if (task.isCompleted) return true;
    if (isTaskRecurring(task)) {
      return isOccurrenceCompleted(task.id, startOfDay(now), this.completions);
    }
    return false;
  }

  getFilteredTasks(): { active: Task[]; completed: Task[] } {
    let tasks = [...this.tasks];
    const now = new Date();

    switch (this.scope) {
      case 'pending':
        tasks = tasks.filter((task) => !this.isEffectivelyCompleted(task, now));
        break;
      case 'week':
        tasks = tasks.filter(
          (task) =>
            !this.isEffectivelyCompleted(task, now) &&
            task.dueDate &&
            isDueInWeekRange(task.dueDate, now)
        );
        break;
      case 'overdue':
        tasks = tasks.filter(
          (task) =>
            task.dueDate &&
            !isTaskRecurrenceEnded(task, now) &&
            isTaskOverdue({
              dueDate: task.dueDate,
              isAllDay: task.isAllDay,
              isCompleted: this.isEffectivelyCompleted(task, now),
              now,
            })
        );
        break;
      case 'all':
        break;
    }

    const active = tasks.filter((task) => !this.isEffectivelyCompleted(task, now));
    const completed = tasks.filter((task) => this.isEffectivelyCompleted(task, now));
    return { active, completed };
  }

  getStats(): {
    pending: number;
    overdue: number;
    week: number;
    all: number;
  } {
    const now = new Date();
    const pending = this.tasks.filter(
      (task) => !this.isEffectivelyCompleted(task, now)
    ).length;
    const overdue = this.tasks.filter(
      (task) =>
        task.dueDate &&
        !isTaskRecurrenceEnded(task, now) &&
        isTaskOverdue({
          dueDate: task.dueDate,
          isAllDay: task.isAllDay,
          isCompleted: this.isEffectivelyCompleted(task, now),
          now,
        })
    ).length;
    const weekCount = this.tasks.filter(
      (task) =>
        !this.isEffectivelyCompleted(task, now) &&
        task.dueDate &&
        isDueInWeekRange(task.dueDate, now)
    ).length;

    return {
      pending,
      overdue,
      week: weekCount,
      all: this.tasks.length,
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
