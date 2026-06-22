import { Task } from '../../models/task';
import {
  getWeekDates,
  isDueOnDate,
  isSameDay,
  weekdayLabel,
} from '../../utils/date_filter';

export function renderWeekView(options: {
  selectedDate: Date;
  tasks: Task[];
  onSelectDate: (date: Date) => void;
}): HTMLElement {
  const wrap = document.createElement('div');
  wrap.className = 'tempo-calendar-view-box';

  const now = new Date();
  const days = getWeekDates(options.selectedDate);
  const row = document.createElement('div');
  row.style.cssText = 'display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:4px;';

  days.forEach((day, index) => {
    const isSelected = isSameDay(day, options.selectedDate);
    const isToday = isSameDay(day, now);
    const hasTask = options.tasks.some(
      (task) => task.dueDate && isDueOnDate(task.dueDate, day)
    );

    const button = document.createElement('button');
    button.type = 'button';
    button.style.cssText = `
      border:0.8px solid ${isSelected ? 'var(--tempo-fg)' : isToday ? 'rgba(10,10,10,0.3)' : 'var(--tempo-border-strong)'};
      background:${isSelected ? 'var(--tempo-fg)' : 'var(--tempo-bg)'};
      border-radius:var(--tempo-radius-md);
      padding:12px 6px;
      cursor:pointer;
      box-shadow:${isSelected ? '0 1px 4px rgba(0,0,0,0.08)' : 'none'};
    `;

    const weekday = document.createElement('div');
    weekday.textContent = weekdayLabel(day.getDay() === 0 ? 7 : day.getDay());
    weekday.style.cssText = `
      font-family:var(--tempo-font-mono);
      font-size:10px;
      font-weight:700;
      letter-spacing:1px;
      color:${isSelected ? '#fff' : 'var(--tempo-fg-muted)'};
    `;

    const dateNum = document.createElement('div');
    dateNum.textContent = `${day.getDate()}`;
    dateNum.style.cssText = `
      margin-top:4px;
      font-family:var(--tempo-font-mono);
      font-size:16px;
      font-weight:700;
      color:${isSelected ? '#fff' : 'var(--tempo-fg-secondary)'};
    `;

    const dot = document.createElement('div');
    dot.style.cssText = `
      width:4px;
      height:4px;
      border-radius:999px;
      margin:4px auto 0;
      background:${hasTask ? (isSelected ? '#fff' : 'var(--tempo-fg-faint)') : 'transparent'};
    `;

    button.appendChild(weekday);
    button.appendChild(dateNum);
    button.appendChild(dot);
    button.addEventListener('click', () => options.onSelectDate(day));
    row.appendChild(button);
  });

  wrap.appendChild(row);
  return wrap;
}
