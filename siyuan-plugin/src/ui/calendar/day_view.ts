import {
  cnWeekday,
  formatDayLabel,
  isSameDay,
  startOfDay,
} from '../../utils/date_filter';

export function renderDayView(options: {
  selectedDate: Date;
  onChange: (date: Date) => void;
}): HTMLElement {
  const wrap = document.createElement('div');
  wrap.className = 'tempo-calendar-view-box';
  wrap.style.padding = '18px';

  const now = new Date();
  const isToday = isSameDay(options.selectedDate, now);
  const isFuture = startOfDay(options.selectedDate).getTime() > startOfDay(now).getTime();

  const row = document.createElement('div');
  row.style.cssText = 'display:flex;align-items:center;justify-content:space-between;gap:12px;';

  const prev = createNavButton('‹', !isToday, () => {
    const next = new Date(options.selectedDate);
    next.setDate(next.getDate() - 1);
    options.onChange(next);
  });

  const center = document.createElement('div');
  center.style.cssText = 'flex:1;text-align:center;';

  const label = document.createElement('div');
  label.textContent = 'SELECTED DAY';
  label.style.cssText = `
    font-family:var(--tempo-font-mono);
    font-size:10px;
    font-weight:700;
    letter-spacing:1.6px;
    color:var(--tempo-fg-subtle);
  `;

  const title = document.createElement('div');
  title.textContent = formatDayLabel(options.selectedDate);
  title.style.cssText = `
    margin-top:4px;
    font-size:22px;
    font-weight:700;
    letter-spacing:-0.5px;
    color:var(--tempo-fg);
  `;

  const sub = document.createElement('div');
  sub.textContent = isToday ? '今天' : `周${cnWeekday(options.selectedDate)}`;
  sub.style.cssText = `
    margin-top:4px;
    font-family:var(--tempo-font-mono);
    font-size:11px;
    color:var(--tempo-fg-muted);
  `;

  center.appendChild(label);
  center.appendChild(title);
  center.appendChild(sub);

  const next = createNavButton('›', isFuture, () => {
    const date = new Date(options.selectedDate);
    date.setDate(date.getDate() + 1);
    options.onChange(date);
  });

  row.appendChild(prev);
  row.appendChild(center);
  row.appendChild(next);
  wrap.appendChild(row);
  return wrap;
}

function createNavButton(
  label: string,
  enabled: boolean,
  onClick: () => void
): HTMLButtonElement {
  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = label;
  button.disabled = !enabled;
  button.style.cssText = `
    width:40px;
    height:40px;
    border:0.8px solid var(--tempo-border-strong);
    border-radius:var(--tempo-radius-md);
    background:var(--tempo-bg);
    color:var(--tempo-fg-muted);
    font-size:20px;
    cursor:${enabled ? 'pointer' : 'default'};
    opacity:${enabled ? '1' : '0.3'};
  `;
  button.addEventListener('click', onClick);
  return button;
}
