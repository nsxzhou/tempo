import { TaskStore } from '../data/task_store';
import { mountCalendarView } from './calendar_view';
import { mountTasksView } from './tasks_view';

export type AppPage = 'tasks' | 'calendar';

export function renderAppShell(
  container: HTMLElement,
  store: TaskStore,
  options: { onUnbind: () => void }
): () => void {
  container.innerHTML = '';

  const shell = document.createElement('div');
  shell.className = 'tempo-app-shell';

  const topTabs = document.createElement('div');
  topTabs.className = 'tempo-top-tabs';

  const tasksTab = document.createElement('button');
  tasksTab.type = 'button';
  tasksTab.className = 'tempo-top-tab is-active';
  tasksTab.textContent = '待办';

  const calendarTab = document.createElement('button');
  calendarTab.type = 'button';
  calendarTab.className = 'tempo-top-tab';
  calendarTab.textContent = '日历';

  topTabs.appendChild(tasksTab);
  topTabs.appendChild(calendarTab);

  const tasksPanel = document.createElement('div');
  tasksPanel.className = 'tempo-page-panel is-active';

  const calendarPanel = document.createElement('div');
  calendarPanel.className = 'tempo-page-panel';

  shell.appendChild(topTabs);
  shell.appendChild(tasksPanel);
  shell.appendChild(calendarPanel);
  container.appendChild(shell);

  let activePage: AppPage = 'tasks';

  const setPage = (page: AppPage): void => {
    activePage = page;
    tasksTab.classList.toggle('is-active', page === 'tasks');
    calendarTab.classList.toggle('is-active', page === 'calendar');
    tasksPanel.classList.toggle('is-active', page === 'tasks');
    calendarPanel.classList.toggle('is-active', page === 'calendar');
  };

  tasksTab.addEventListener('click', () => setPage('tasks'));
  calendarTab.addEventListener('click', () => setPage('calendar'));

  const cleanupTasks = mountTasksView(tasksPanel, store, options);
  const cleanupCalendar = mountCalendarView(calendarPanel, store, options);

  return () => {
    cleanupTasks();
    cleanupCalendar();
  };
}
