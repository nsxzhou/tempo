import { Task, TaskPriority } from '../../models/task';
import {
  createPillBadge,
  priorityBadgeKind,
} from '../components/pill_badge';
import { formatTimeShort } from '../../utils/date_filter';

export function createCalendarTaskRow(options: {
  task: Task;
  onTap: () => void;
}): HTMLElement {
  const { task } = options;
  const row = document.createElement('button');
  row.type = 'button';
  row.style.cssText = `
    width: 100%;
    text-align: left;
    border: 0.8px solid var(--tempo-border-strong);
    border-radius: var(--tempo-radius-md);
    background: var(--tempo-bg);
    box-shadow: var(--tempo-shadow-sm);
    padding: 14px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 12px;
  `;

  const main = document.createElement('div');
  main.style.cssText = 'flex:1;min-width:0;';

  const title = document.createElement('div');
  title.textContent = task.title;
  title.style.cssText = `
    font-size: 13px;
    font-weight: 600;
    letter-spacing: -0.2px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    color: var(--tempo-fg);
  `;
  main.appendChild(title);

  const meta = document.createElement('div');
  meta.style.cssText = 'display:flex;align-items:center;gap:6px;margin-top:6px;';

  if (task.priority !== TaskPriority.none) {
    meta.appendChild(
      createPillBadge(`P${task.priority - 1}`, priorityBadgeKind(task.priority))
    );
  }

  if (task.dueDate && !task.isAllDay) {
    const time = document.createElement('span');
    time.textContent = formatTimeShort(task.dueDate);
    time.style.cssText = `
      font-family: var(--tempo-font-mono);
      font-size: 10px;
      color: var(--tempo-fg-muted);
    `;
    meta.appendChild(time);
  }

  if (meta.childElementCount > 0) {
    main.appendChild(meta);
  }

  row.appendChild(main);

  if (task.isCompleted) {
    row.appendChild(createPillBadge('已完成', 'success'));
  } else {
    const chevron = document.createElement('span');
    chevron.textContent = '›';
    chevron.style.cssText = 'color:var(--tempo-fg-faint);font-size:16px;';
    row.appendChild(chevron);
  }

  row.addEventListener('click', options.onTap);
  return row;
}
