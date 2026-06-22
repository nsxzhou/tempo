import { TAG_LIFE, TAG_WORK } from '../constants';
import { Task } from '../models/task';
import { isDueInWeekRange, isTaskOverdue } from '../utils/date_filter';
import {
  createTask,
  deleteTask,
  fetchTasks,
  toggleTaskComplete,
  updateTask,
  type CreateTaskInput,
  type TaskFormInput,
  type UpdateTaskInput,
} from './task_repository';

export type TimeFilter = 'today' | 'week' | 'overdue' | 'all';
export type CategoryFilter = 'all' | 'work' | 'life';

type Listener = () => void;

export class TaskStore {
  private tasks: Task[] = [];
  private listeners = new Set<Listener>();
  private loading = false;
  private error: string | null = null;

  timeFilter: TimeFilter = 'today';
  categoryFilter: CategoryFilter = 'all';

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

  getLoading(): boolean {
    return this.loading;
  }

  getError(): string | null {
    return this.error;
  }

  setTimeFilter(filter: TimeFilter): void {
    this.timeFilter = filter;
    this.notify();
  }

  setCategoryFilter(filter: CategoryFilter): void {
    this.categoryFilter = filter;
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

  getFilteredTasks(): { active: Task[]; completed: Task[] } {
    let tasks = [...this.tasks];
    const now = new Date();

    switch (this.timeFilter) {
      case 'today':
        tasks = tasks.filter((task) => !task.isCompleted);
        break;
      case 'week':
        tasks = tasks.filter(
          (task) => task.dueDate && isDueInWeekRange(task.dueDate, now)
        );
        break;
      case 'overdue':
        tasks = tasks.filter(
          (task) =>
            task.dueDate &&
            isTaskOverdue({
              dueDate: task.dueDate,
              isAllDay: task.isAllDay,
              isCompleted: task.isCompleted,
              now,
            })
        );
        break;
      case 'all':
        break;
    }

    if (this.categoryFilter === 'work') {
      tasks = tasks.filter((task) => task.tag === TAG_WORK);
    } else if (this.categoryFilter === 'life') {
      tasks = tasks.filter((task) => task.tag === TAG_LIFE);
    }

    const active = tasks.filter((task) => !task.isCompleted);
    const completed = tasks.filter((task) => task.isCompleted);
    return { active, completed };
  }

  getStats(): {
    pending: number;
    overdue: number;
    weekCount: number;
    total: number;
    work: number;
    life: number;
  } {
    const now = new Date();
    const pending = this.tasks.filter((task) => !task.isCompleted).length;
    const overdue = this.tasks.filter(
      (task) =>
        task.dueDate &&
        isTaskOverdue({
          dueDate: task.dueDate,
          isAllDay: task.isAllDay,
          isCompleted: task.isCompleted,
          now,
        })
    ).length;
    const weekCount = this.tasks.filter(
      (task) => task.dueDate && isDueInWeekRange(task.dueDate, now)
    ).length;
    const work = this.tasks.filter((task) => task.tag === TAG_WORK).length;
    const life = this.tasks.filter((task) => task.tag === TAG_LIFE).length;

    return {
      pending,
      overdue,
      weekCount,
      total: this.tasks.length,
      work,
      life,
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

  async toggleComplete(task: Task): Promise<void> {
    const updated = await toggleTaskComplete(task);
    this.tasks = this.tasks.map((item) => (item.id === updated.id ? updated : item));
    this.notify();
  }

  async removeTask(taskId: string): Promise<void> {
    await deleteTask(taskId);
    this.tasks = this.tasks.filter((task) => task.id !== taskId);
    this.notify();
  }
}
