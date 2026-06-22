import { Task, priorityLabel } from '../../models/task';
import { TAG_LIFE, TAG_WORK } from '../../constants';
import { formatTaskDueLabel } from '../../utils/date_filter';
import { createCheckbox } from './checkbox';

export function createTaskRow(options: {
  task: Task;
  onTap: () => void;
  onToggleComplete: () => void;
  onDelete: () => void;
}): HTMLElement {
  const { task } = options;
  const row = document.createElement('div');
  row.className = 'tempo-task-row';
  row.style.cssText = `
    display: flex;
    align-items: center;
    gap: 12px;
    min-height: 52px;
    padding: 0 14px;
    border: 0.8px solid ${task.isCompleted ? 'var(--tempo-border-subtle)' : 'var(--tempo-border-strong)'};
    border-radius: var(--tempo-radius-md);
    background: var(--tempo-bg);
    box-shadow: ${task.isCompleted ? 'none' : 'var(--tempo-shadow-sm)'};
    opacity: ${task.isCompleted ? '0.72' : '1'};
    cursor: pointer;
    transition: opacity var(--tempo-duration-fast) ease;
  `;

  const checkbox = createCheckbox({
    checked: task.isCompleted,
    onToggle: options.onToggleComplete,
  });

  const main = document.createElement('div');
  main.style.cssText = 'flex:1;min-width:0;display:flex;flex-direction:column;gap:4px;';

  const titleRow = document.createElement('div');
  titleRow.style.cssText = 'display:flex;align-items:center;gap:8px;min-width:0;';

  const title = document.createElement('span');
  title.textContent = task.title;
  title.style.cssText = `
    font-size: 14px;
    font-weight: 500;
    color: var(--tempo-fg);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    text-decoration: ${task.isCompleted ? 'line-through' : 'none'};
  `;
  titleRow.appendChild(title);

  const badge = priorityLabel(task.priority);
  if (badge) {
    const pill = document.createElement('span');
    pill.textContent = badge;
    pill.style.cssText = `
      font-size: 10px;
      padding: 2px 6px;
      border-radius: 999px;
      background: var(--tempo-bg-muted);
      color: var(--tempo-fg-muted);
      flex-shrink: 0;
    `;
    titleRow.appendChild(pill);
  }

  main.appendChild(titleRow);

  const meta = document.createElement('div');
  meta.style.cssText = `
    display:flex;
    align-items:center;
    gap:8px;
    font-family: var(--tempo-font-mono);
    font-size: 11px;
    color: var(--tempo-fg-subtle);
  `;

  if (task.dueDate) {
    const due = document.createElement('span');
    due.textContent = formatTaskDueLabel({
      dueDate: task.dueDate,
      isAllDay: task.isAllDay,
    });
    meta.appendChild(due);
  }

  if (task.tag === TAG_WORK) {
    const tag = document.createElement('span');
    tag.textContent = '@工作';
    meta.appendChild(tag);
  } else if (task.tag === TAG_LIFE) {
    const tag = document.createElement('span');
    tag.textContent = '@生活';
    meta.appendChild(tag);
  }

  if (meta.childElementCount > 0) {
    main.appendChild(meta);
  }

  const deleteBtn = document.createElement('button');
  deleteBtn.type = 'button';
  deleteBtn.setAttribute('aria-label', '删除任务');
  deleteBtn.textContent = '×';
  deleteBtn.style.cssText = `
    width: 28px;
    height: 28px;
    border: none;
    background: transparent;
    color: var(--tempo-fg-subtle);
    font-size: 18px;
    line-height: 1;
    border-radius: var(--tempo-radius-sm);
    cursor: pointer;
    opacity: 0;
    transition: opacity var(--tempo-duration-fast) ease, background var(--tempo-duration-fast) ease;
  `;
  deleteBtn.addEventListener('click', (event) => {
    event.stopPropagation();
    options.onDelete();
  });

  row.addEventListener('mouseenter', () => {
    deleteBtn.style.opacity = '1';
  });
  row.addEventListener('mouseleave', () => {
    deleteBtn.style.opacity = '0';
  });
  deleteBtn.addEventListener('mouseenter', () => {
    deleteBtn.style.background = 'var(--tempo-bg-muted)';
  });
  deleteBtn.addEventListener('mouseleave', () => {
    deleteBtn.style.background = 'transparent';
  });

  row.appendChild(checkbox);
  row.appendChild(main);
  row.appendChild(deleteBtn);
  row.addEventListener('click', options.onTap);

  return row;
}
