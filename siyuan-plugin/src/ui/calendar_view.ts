import { TaskStore } from '../data/task_store';
import type { TaskFormInput } from '../data/task_repository';
import {
  formatDayLabel,
  formatMonthLabel,
  getWeekNumber,
} from '../utils/date_filter';
import { renderDayView } from './calendar/day_view';
import { renderMonthView } from './calendar/month_view';
import { renderSelectedDayPanel } from './calendar/selected_day_panel';
import { renderWeekView } from './calendar/week_view';
import { createSegmentedControl } from './components/seg_control';
import { openSettingsDialog } from './dialogs/settings';

type CalendarViewMode = 'month' | 'week' | 'day';

export function mountCalendarView(
  panel: HTMLElement,
  store: TaskStore,
  options: { onUnbind: () => void }
): () => void {
  panel.innerHTML = '';

  let viewMode: CalendarViewMode = 'month';
  let selectedDate = new Date();

  const scroll = document.createElement('div');
  scroll.className = 'tempo-page-scroll';

  const header = document.createElement('div');
  header.className = 'tempo-page-header';

  const headerMain = document.createElement('div');
  headerMain.className = 'tempo-page-header-main';

  const title = document.createElement('h1');
  title.className = 'tempo-page-title';
  title.textContent = '日历';

  const subtitle = document.createElement('div');
  subtitle.className = 'tempo-page-subtitle';

  headerMain.appendChild(title);
  headerMain.appendChild(subtitle);

  const actions = document.createElement('div');
  actions.className = 'tempo-header-actions';

  const settingsBtn = document.createElement('button');
  settingsBtn.type = 'button';
  settingsBtn.className = 'tempo-icon-btn';
  settingsBtn.setAttribute('aria-label', '设置');
  settingsBtn.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.26.604.852.997 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"/></svg>`;
  settingsBtn.addEventListener('click', () => {
    openSettingsDialog({ onUnbind: options.onUnbind });
  });

  actions.appendChild(settingsBtn);
  header.appendChild(headerMain);
  header.appendChild(actions);

  const toolbar = document.createElement('div');
  toolbar.className = 'tempo-calendar-toolbar';

  const segWrap = document.createElement('div');
  segWrap.className = 'tempo-calendar-toolbar-grow';

  const todayBtn = document.createElement('button');
  todayBtn.type = 'button';
  todayBtn.className = 'tempo-today-btn';
  todayBtn.textContent = '今日';
  todayBtn.addEventListener('click', () => {
    selectedDate = new Date();
    viewMode = 'month';
    render();
  });

  toolbar.appendChild(segWrap);
  toolbar.appendChild(todayBtn);

  const split = document.createElement('div');
  split.className = 'tempo-calendar-split';

  const viewHost = document.createElement('div');
  const panelHost = document.createElement('div');

  split.appendChild(viewHost);
  split.appendChild(panelHost);

  scroll.appendChild(header);
  scroll.appendChild(toolbar);
  scroll.appendChild(split);
  panel.appendChild(scroll);

  const updateSubtitle = (): void => {
    const now = new Date();
    if (viewMode === 'month') {
      subtitle.textContent = formatMonthLabel(selectedDate);
      return;
    }
    if (viewMode === 'week') {
      subtitle.textContent = `${formatMonthLabel(selectedDate)} · 第 ${getWeekNumber(selectedDate, now)} 周`;
      return;
    }
    subtitle.textContent = formatDayLabel(selectedDate);
  };

  const renderSegment = (): void => {
    segWrap.innerHTML = '';
    segWrap.appendChild(
      createSegmentedControl<CalendarViewMode>({
        value: viewMode,
        items: [
          { value: 'month', label: '月' },
          { value: 'week', label: '周' },
          { value: 'day', label: '日' },
        ],
        onChange: (value) => {
          viewMode = value;
          render();
        },
      })
    );
  };

  const render = (): void => {
    updateSubtitle();
    renderSegment();

    if (store.getLoading() && store.getTasks().length === 0) {
      viewHost.innerHTML = '<div class="tempo-loading-state">加载中…</div>';
      panelHost.innerHTML = '';
      return;
    }

    const tasks = store.getTasks();
    viewHost.innerHTML = '';
    panelHost.innerHTML = '';

    if (viewMode === 'month') {
      viewHost.appendChild(
        renderMonthView({
          selectedDate,
          tasks,
          onSelectDate: (date) => {
            selectedDate = date;
            render();
          },
        })
      );
    } else if (viewMode === 'week') {
      viewHost.appendChild(
        renderWeekView({
          selectedDate,
          tasks,
          onSelectDate: (date) => {
            selectedDate = date;
            render();
          },
        })
      );
    } else {
      viewHost.appendChild(
        renderDayView({
          selectedDate,
          onChange: (date) => {
            selectedDate = date;
            render();
          },
        })
      );
    }

    panelHost.appendChild(
      renderSelectedDayPanel({
        selectedDate,
        tasks,
        onEditTask: async (task, input: TaskFormInput) => {
          await store.editTask(task, input);
        },
      })
    );
  };

  const unsubscribe = store.subscribe(render);
  render();

  return () => {
    unsubscribe();
  };
}
