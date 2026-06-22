import { Task } from '../../models/task';
import { formatMonthYearShort, isDueOnDate } from '../../utils/date_filter';
import { createCalendarTaskRow } from '../components/calendar_task_row';
import { openTaskFormDialog } from '../dialogs/task_form';

export function renderSelectedDayPanel(options: {
  selectedDate: Date;
  tasks: Task[];
  onEditTask: (task: Task, input: import('../../data/task_repository').TaskFormInput) => Promise<void>;
}): HTMLElement {
  const panel = document.createElement('div');
  panel.className = 'tempo-selected-day-panel';

  const dayTasks = options.tasks.filter(
    (task) => task.dueDate && isDueOnDate(task.dueDate, options.selectedDate)
  );

  const header = document.createElement('div');
  header.style.cssText = 'display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;';

  const title = document.createElement('div');
  title.textContent = `待办日程 (${dayTasks.length} 项)`;
  title.style.cssText = `
    font-size:11px;
    font-weight:700;
    letter-spacing:1px;
    color:var(--tempo-fg);
  `;

  const meta = document.createElement('div');
  meta.textContent = formatMonthYearShort(options.selectedDate);
  meta.style.cssText = `
    font-family:var(--tempo-font-mono);
    font-size:10px;
    font-weight:700;
    color:var(--tempo-fg-subtle);
  `;

  header.appendChild(title);
  header.appendChild(meta);
  panel.appendChild(header);

  if (dayTasks.length === 0) {
    const empty = document.createElement('div');
    empty.textContent = '本日暂无排期日程';
    empty.style.cssText = `
      padding:24px;
      text-align:center;
      border:0.5px solid var(--tempo-border-strong);
      border-radius:var(--tempo-radius-md);
      background:var(--tempo-bg-muted);
      color:var(--tempo-fg-muted);
      font-size:12px;
      font-weight:600;
    `;
    panel.appendChild(empty);
    return panel;
  }

  const list = document.createElement('div');
  list.style.cssText = 'display:flex;flex-direction:column;gap:8px;';

  for (const task of dayTasks) {
    list.appendChild(
      createCalendarTaskRow({
        task,
        onTap: () => {
          openTaskFormDialog({
            task,
            onSubmit: async (input) => options.onEditTask(task, input),
          });
        },
      })
    );
  }

  panel.appendChild(list);
  return panel;
}
