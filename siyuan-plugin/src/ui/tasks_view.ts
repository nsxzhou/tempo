import { Task } from '../models/task';
import { formatHeaderDate } from '../utils/date_filter';
import {
  CategoryFilter,
  TaskStore,
  TimeFilter,
} from '../data/task_store';
import type { TaskFormInput } from '../data/task_repository';
import { createBentoCard } from './components/bento_card';
import { createSegmentedControl } from './components/seg_control';
import { createTaskRow } from './components/task_row';
import { openSettingsDialog } from './dialogs/settings';
import { openTaskFormDialog } from './dialogs/task_form';

export function mountTasksView(
  panel: HTMLElement,
  store: TaskStore,
  options: { onUnbind: () => void }
): () => void {
  panel.innerHTML = '';

  const scroll = document.createElement('div');
  scroll.className = 'tempo-page-scroll';

  const fab = document.createElement('button');
  fab.type = 'button';
  fab.className = 'tempo-fab';
  fab.setAttribute('aria-label', '新建任务');
  fab.textContent = '+';
  fab.addEventListener('click', () => {
    openTaskFormDialog({
      onSubmit: async (input: TaskFormInput) => {
        await store.addTask(input);
      },
    });
  });

  panel.appendChild(scroll);
  panel.appendChild(fab);

  const render = (): void => {
    scroll.innerHTML = '';

    if (store.getLoading() && store.getTasks().length === 0) {
      const loading = document.createElement('div');
      loading.className = 'tempo-loading-state';
      loading.textContent = '加载中…';
      scroll.appendChild(loading);
      return;
    }

    if (store.getError()) {
      const error = document.createElement('div');
      error.className = 'tempo-error-banner';
      error.textContent = store.getError() ?? '加载失败';
      scroll.appendChild(error);
    }

    scroll.appendChild(buildHeader(store, options.onUnbind));
    scroll.appendChild(buildBento(store));
    scroll.appendChild(buildSegmented(store));
    scroll.appendChild(buildTaskList(store));
  };

  const unsubscribe = store.subscribe(render);
  render();

  return () => {
    unsubscribe();
  };
}

function buildHeader(store: TaskStore, onUnbind: () => void): HTMLElement {
  const header = document.createElement('div');
  header.className = 'tempo-page-header';

  const left = document.createElement('div');
  left.className = 'tempo-page-header-main';

  const title = document.createElement('h1');
  title.className = 'tempo-page-title';
  title.textContent = 'TODO';

  const date = document.createElement('div');
  date.className = 'tempo-page-subtitle';
  date.textContent = formatHeaderDate();

  left.appendChild(title);
  left.appendChild(date);

  const actions = document.createElement('div');
  actions.className = 'tempo-header-actions';

  const createBtn = document.createElement('button');
  createBtn.type = 'button';
  createBtn.className = 'tempo-text-btn';
  createBtn.textContent = '新建';
  createBtn.addEventListener('click', () => {
    openTaskFormDialog({
      onSubmit: async (input: TaskFormInput) => {
        await store.addTask(input);
      },
    });
  });

  const settingsBtn = document.createElement('button');
  settingsBtn.type = 'button';
  settingsBtn.className = 'tempo-icon-btn';
  settingsBtn.setAttribute('aria-label', '设置');
  settingsBtn.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.26.604.852.997 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"/></svg>`;
  settingsBtn.addEventListener('click', () => {
    openSettingsDialog({ onUnbind });
  });

  actions.appendChild(createBtn);
  actions.appendChild(settingsBtn);
  header.appendChild(left);
  header.appendChild(actions);
  return header;
}

function buildBento(store: TaskStore): HTMLElement {
  const stats = store.getStats();
  const wrap = document.createElement('div');
  wrap.className = 'tempo-bento-grid';

  const cards: Array<{
    filter: TimeFilter;
    label: string;
    value: string;
    unit: string;
    dotColor: string;
    dotPulse?: boolean;
    errorTone?: boolean;
  }> = [
    {
      filter: 'today',
      label: '今日待办',
      value: `${stats.pending}`,
      unit: '项未完成',
      dotColor: 'var(--tempo-p2)',
    },
    {
      filter: 'overdue',
      label: '已过期',
      value: `${stats.overdue}`,
      unit: '项超期',
      dotColor: stats.overdue > 0 ? 'var(--tempo-p0)' : 'var(--tempo-fg-muted)',
      dotPulse: stats.overdue > 0,
      errorTone: stats.overdue > 0,
    },
    {
      filter: 'week',
      label: '本周安排',
      value: `${stats.weekCount}`,
      unit: '项总代办',
      dotColor: 'var(--tempo-fg-faint)',
    },
    {
      filter: 'all',
      label: '全部任务',
      value: `${stats.total}`,
      unit: '项总代办',
      dotColor: 'var(--tempo-success)',
    },
  ];

  for (const card of cards) {
    wrap.appendChild(
      createBentoCard({
        label: card.label,
        value: card.value,
        unit: card.unit,
        selected: store.timeFilter === card.filter,
        dotColor: card.dotColor,
        dotPulse: card.dotPulse,
        errorTone: card.errorTone,
        onTap: () => store.setTimeFilter(card.filter),
      })
    );
  }

  return wrap;
}

function buildSegmented(store: TaskStore): HTMLElement {
  const stats = store.getStats();
  const wrap = document.createElement('div');
  wrap.className = 'tempo-section-pad';
  wrap.appendChild(
    createSegmentedControl<CategoryFilter>({
      value: store.categoryFilter,
      items: [
        { value: 'all', label: '全部', count: stats.total },
        { value: 'work', label: '工作', count: stats.work },
        { value: 'life', label: '生活', count: stats.life },
      ],
      onChange: (value) => store.setCategoryFilter(value),
    })
  );
  return wrap;
}

function buildTaskList(store: TaskStore): HTMLElement {
  const wrap = document.createElement('div');
  wrap.className = 'tempo-section-pad';

  const { active, completed } = store.getFilteredTasks();

  if (active.length === 0 && completed.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'tempo-empty-state';
    empty.textContent = '暂无任务';
    wrap.appendChild(empty);
    return wrap;
  }

  if (active.length > 0) {
    wrap.appendChild(sectionHeader(`待办 · ${active.length}`));
    const list = document.createElement('div');
    list.className = 'tempo-task-list';
    for (const task of active) {
      list.appendChild(buildRow(store, task));
    }
    wrap.appendChild(list);
  }

  if (completed.length > 0) {
    wrap.appendChild(sectionHeader(`已完成 · ${completed.length}`));
    const list = document.createElement('div');
    list.className = 'tempo-task-list';
    for (const task of completed) {
      list.appendChild(buildRow(store, task));
    }
    wrap.appendChild(list);
  }

  return wrap;
}

function sectionHeader(label: string): HTMLElement {
  const header = document.createElement('div');
  header.className = 'tempo-section-header';
  header.textContent = label;
  return header;
}

function buildRow(store: TaskStore, task: Task): HTMLElement {
  return createTaskRow({
    task,
    onTap: () => {
      openTaskFormDialog({
        task,
        onSubmit: async (input) => {
          await store.editTask(task, input);
        },
      });
    },
    onToggleComplete: () => {
      void store.toggleComplete(task);
    },
    onDelete: () => {
      void store.removeTask(task.id);
    },
  });
}
