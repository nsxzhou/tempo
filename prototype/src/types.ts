export type Priority = 'p0' | 'p1' | 'p2' | 'p3';

export interface SubTask {
  id: string;
  title: string;
  completed: boolean;
}

export interface SiYuanLink {
  title: string;
  url: string;
}

export interface Task {
  id: string;
  title: string;
  priority: Priority;
  deadline: string;
  tag: string;
  completed: boolean;
  overdue: boolean;
  description: string;
  siyuanLink: SiYuanLink | null;
  subtasks: SubTask[];
  estimate: string;
  allocatedTime: string;
  energyMatch: string;
}

export interface PlannerBlock {
  id: string;
  start: string;
  end: string;
  title: string;
  reason: string;
  tag: 'calendar' | 'p0' | 'p1' | 'p2' | 'p3' | 'break' | 'buff';
  active: boolean;
}

export type TabName = 'tasks' | 'calendar' | 'plan' | 'settings' | 'detail';
