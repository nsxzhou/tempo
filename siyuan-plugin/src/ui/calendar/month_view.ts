import { Task } from '../../models/task';
import {
  getMonthGrid,
  isDueOnDate,
  isSameDay,
  priorityDotColor,
} from '../../utils/date_filter';

export function renderMonthView(options: {
  selectedDate: Date;
  tasks: Task[];
  onSelectDate: (date: Date) => void;
}): HTMLElement {
  const wrap = document.createElement('div');
  wrap.className = 'tempo-calendar-view-box';

  const now = new Date();
  const cells = getMonthGrid(options.selectedDate);

  const header = document.createElement('div');
  header.style.cssText = 'display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:2px;margin-bottom:8px;';
  for (const label of ['一', '二', '三', '四', '五', '六', '日']) {
    const cell = document.createElement('div');
    cell.textContent = label;
    cell.style.cssText = `
      text-align:center;
      font-family:var(--tempo-font-mono);
      font-size:10px;
      font-weight:700;
      color:var(--tempo-fg-subtle);
      letter-spacing:0.4px;
    `;
    header.appendChild(cell);
  }
  wrap.appendChild(header);

  const grid = document.createElement('div');
  grid.style.cssText = 'display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:2px;';

  for (const cell of cells) {
    grid.appendChild(createDayCell(cell, options, now));
  }

  wrap.appendChild(grid);
  return wrap;
}

function createDayCell(
  cell: { date: Date; isOtherMonth: boolean },
  options: { selectedDate: Date; tasks: Task[]; onSelectDate: (date: Date) => void },
  now: Date
): HTMLElement {
  const button = document.createElement('button');
  button.type = 'button';
  button.disabled = cell.isOtherMonth;
  button.style.cssText = `
    border:none;
    background:transparent;
    padding:4px 0;
    cursor:${cell.isOtherMonth ? 'default' : 'pointer'};
    opacity:${cell.isOtherMonth ? '0.45' : '1'};
  `;

  const isSelected = isSameDay(cell.date, options.selectedDate) && !cell.isOtherMonth;
  const isToday = isSameDay(cell.date, now);
  const dots = dotsForDay(cell.date, options.tasks);

  const day = document.createElement('div');
  day.textContent = `${cell.date.getDate()}`;
  day.style.cssText = `
    width:28px;
    height:28px;
    margin:0 auto;
    display:flex;
    align-items:center;
    justify-content:center;
    border-radius:999px;
    font-family:var(--tempo-font-mono);
    font-size:12px;
    font-weight:600;
    color:${isSelected ? '#fff' : cell.isOtherMonth ? 'var(--tempo-fg-faint)' : isToday ? 'var(--tempo-fg)' : 'var(--tempo-fg-secondary)'};
    background:${isSelected ? 'var(--tempo-fg)' : 'transparent'};
    border:${isToday && !isSelected ? '1px solid var(--tempo-fg)' : '1px solid transparent'};
  `;

  const dotRow = document.createElement('div');
  dotRow.style.cssText = 'display:flex;justify-content:center;gap:2px;height:3px;margin-top:2px;';
  for (let i = 0; i < 3; i += 1) {
    const dot = document.createElement('span');
    dot.style.cssText = `
      width:3px;
      height:3px;
      border-radius:999px;
      background:${dots[i] ? (isSelected ? '#fff' : dots[i]) : 'transparent'};
    `;
    dotRow.appendChild(dot);
  }

  button.appendChild(day);
  button.appendChild(dotRow);

  if (!cell.isOtherMonth) {
    button.addEventListener('click', () => options.onSelectDate(cell.date));
  }

  return button;
}

function dotsForDay(day: Date, tasks: Task[]): string[] {
  const dayTasks = tasks.filter(
    (task) => task.dueDate && !task.isCompleted && isDueOnDate(task.dueDate, day)
  );
  const seen = new Set<number>();
  const dots: string[] = [];

  for (const task of dayTasks) {
    if (seen.has(task.priority)) continue;
    seen.add(task.priority);
    dots.push(priorityDotColor(task.priority));
    if (dots.length >= 3) break;
  }

  return dots;
}
