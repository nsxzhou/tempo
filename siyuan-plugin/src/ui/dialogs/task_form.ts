import { Dialog } from 'siyuan';
import { Task, TaskPriority } from '../../models/task';
import { TAG_LIFE, TAG_WORK } from '../../constants';
import {
  parseDueDate,
  toDateInputValue,
  toTimeInputValue,
} from '../../utils/date_filter';
import {
  hasRecurrence,
  RECURRENCE_NONE,
  RecurrenceConfig,
  RecurrenceUnit,
  recurrenceConfigFromTask,
  recurrenceConfigToRRule,
} from '../../utils/recurrence_config';
import type { TaskFormInput } from '../../data/task_repository';

function priorityStyles(priority: TaskPriority, selected: boolean): string {
  const map: Record<TaskPriority, [string, string, string]> = {
    [TaskPriority.none]: ['var(--tempo-bg-muted)', 'var(--tempo-fg-muted)', 'var(--tempo-border-strong)'],
    [TaskPriority.p0]: ['var(--tempo-p0-bg)', 'var(--tempo-p0)', 'var(--tempo-p0-border)'],
    [TaskPriority.p1]: ['var(--tempo-p1-bg)', 'var(--tempo-p1)', 'var(--tempo-p1-border)'],
    [TaskPriority.p2]: ['var(--tempo-p2-bg)', 'var(--tempo-p2)', 'var(--tempo-p2-border)'],
    [TaskPriority.p3]: ['var(--tempo-p3-bg)', 'var(--tempo-p3)', 'var(--tempo-p3-border)'],
  };
  const [bg, fg, border] = map[priority];
  if (selected) {
    return `background:${fg};color:#fff;border:1px solid ${fg};`;
  }
  return `background:${bg};color:${fg};border:1px solid ${border};`;
}

function fieldLabel(text: string): string {
  return `<div style="font-size:12px;color:var(--tempo-fg-muted);margin-bottom:6px;font-weight:500;">${text}</div>`;
}

function inputStyle(): string {
  return `
    width:100%;
    box-sizing:border-box;
    border:1px solid var(--tempo-border-strong);
    border-radius:var(--tempo-radius-md);
    padding:10px 12px;
    font-size:13px;
    font-family:var(--tempo-font-sans);
    background:var(--tempo-bg);
    color:var(--tempo-fg);
    transition: border-color var(--tempo-duration-fast) ease;
  `;
}

export function openTaskFormDialog(options: {
  task?: Task;
  onSubmit: (input: TaskFormInput) => Promise<void>;
}): void {
  const isEdit = Boolean(options.task);
  const task = options.task;

  const dialog = new Dialog({
    title: isEdit ? '编辑任务' : '新建任务',
    content: `<div class="b3-dialog__content tempo-dialog-inner" style="font-family:var(--tempo-font-sans);">
      ${fieldLabel('标题')}
      <input id="tempo-title" class="b3-text-field fn__block" style="${inputStyle()}" placeholder="输入任务标题" value="${task?.title ? escapeAttr(task.title) : ''}" />
      <div style="height:14px"></div>
      ${fieldLabel('描述')}
      <textarea id="tempo-desc" class="b3-text-field fn__block" style="${inputStyle()} min-height:72px; resize: vertical;" placeholder="可选">${task?.description ? escapeText(task.description) : ''}</textarea>
      <div style="height:14px"></div>
      ${fieldLabel('优先级')}
      <div id="tempo-priority" style="display:flex;gap:8px;flex-wrap:wrap;"></div>
      <div style="height:14px"></div>
      ${fieldLabel('截止日期')}
      <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
        <input id="tempo-date" type="date" style="${inputStyle()} max-width:180px;" value="${task?.dueDate ? toDateInputValue(task.dueDate) : ''}" />
        <input id="tempo-time" type="time" style="${inputStyle()} max-width:120px;" value="${task?.dueDate && !task.isAllDay ? toTimeInputValue(task.dueDate) : '09:00'}" />
        <label style="display:flex;align-items:center;gap:6px;font-size:13px;color:var(--tempo-fg-muted);">
          <input id="tempo-allday" type="checkbox" ${task?.isAllDay ? 'checked' : ''} />
          全天
        </label>
      </div>
      <div style="height:14px"></div>
      ${fieldLabel('重复')}
      <div id="tempo-repeat-wrap" style="border:0.8px solid var(--tempo-border-strong);border-radius:var(--tempo-radius-md);padding:12px;">
        <label style="display:flex;align-items:center;gap:8px;font-size:13px;color:var(--tempo-fg);margin-bottom:10px;">
          <input id="tempo-repeat-enabled" type="checkbox" style="width:16px;height:16px;accent-color:var(--tempo-fg);" />
          启用重复
        </label>
        <div id="tempo-repeat-fields" style="display:none;flex-direction:column;gap:10px;">
          <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;">
            <span style="font-size:13px;color:var(--tempo-fg-muted);">每</span>
            <input id="tempo-repeat-interval" type="number" min="1" max="999" value="1" style="${inputStyle()} max-width:72px;" />
            <select id="tempo-repeat-unit" style="${inputStyle()} max-width:96px;">
              <option value="day">天</option>
              <option value="week">周</option>
              <option value="month">月</option>
            </select>
          </div>
          <div id="tempo-repeat-weekdays" style="display:none;gap:6px;flex-wrap:wrap;"></div>
          <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;">
            <span style="font-size:12px;color:var(--tempo-fg-muted);">结束</span>
            <select id="tempo-repeat-end-mode" style="${inputStyle()} max-width:120px;">
              <option value="never">永不</option>
              <option value="date">日期</option>
              <option value="count">次数</option>
            </select>
            <input id="tempo-repeat-end-date" type="date" style="${inputStyle()} max-width:160px;display:none;" />
            <input id="tempo-repeat-end-count" type="number" min="1" max="999" value="10" style="${inputStyle()} max-width:88px;display:none;" />
          </div>
        </div>
      </div>
      <div style="height:14px"></div>
      ${fieldLabel('分类')}
      <div id="tempo-tag" style="display:flex;gap:8px;flex-wrap:wrap;"></div>
    </div>
    <div class="b3-dialog__action tempo-dialog-actions">
      <button class="b3-button b3-button--cancel tempo-dialog-button tempo-dialog-button--secondary">取消</button>
      <button class="b3-button b3-button--text tempo-dialog-button tempo-dialog-button--primary" id="tempo-save">${isEdit ? '保存' : '创建'}</button>
    </div>`,
    width: '520px',
  });

  const titleInput = dialog.element.querySelector('#tempo-title') as HTMLInputElement;
  const descInput = dialog.element.querySelector('#tempo-desc') as HTMLTextAreaElement;
  const dateInput = dialog.element.querySelector('#tempo-date') as HTMLInputElement;
  const timeInput = dialog.element.querySelector('#tempo-time') as HTMLInputElement;
  const allDayInput = dialog.element.querySelector('#tempo-allday') as HTMLInputElement;
  const priorityWrap = dialog.element.querySelector('#tempo-priority') as HTMLElement;
  const tagWrap = dialog.element.querySelector('#tempo-tag') as HTMLElement;
  const repeatEnabledInput = dialog.element.querySelector('#tempo-repeat-enabled') as HTMLInputElement;
  const repeatFields = dialog.element.querySelector('#tempo-repeat-fields') as HTMLElement;
  const repeatIntervalInput = dialog.element.querySelector('#tempo-repeat-interval') as HTMLInputElement;
  const repeatUnitSelect = dialog.element.querySelector('#tempo-repeat-unit') as HTMLSelectElement;
  const repeatWeekdaysWrap = dialog.element.querySelector('#tempo-repeat-weekdays') as HTMLElement;
  const repeatEndModeSelect = dialog.element.querySelector('#tempo-repeat-end-mode') as HTMLSelectElement;
  const repeatEndDateInput = dialog.element.querySelector('#tempo-repeat-end-date') as HTMLInputElement;
  const repeatEndCountInput = dialog.element.querySelector('#tempo-repeat-end-count') as HTMLInputElement;
  const buttons = dialog.element.querySelectorAll('.b3-button');
  const saveButton = dialog.element.querySelector('#tempo-save') as HTMLButtonElement;

  let selectedPriority = task?.priority ?? TaskPriority.none;
  let selectedTag: string | null = task?.tag ?? null;
  let recurrenceConfig: RecurrenceConfig = task
    ? recurrenceConfigFromTask(task)
    : { ...RECURRENCE_NONE };

  const weekdayOptions: Array<{ value: number; label: string }> = [
    { value: 1, label: '一' },
    { value: 2, label: '二' },
    { value: 3, label: '三' },
    { value: 4, label: '四' },
    { value: 5, label: '五' },
    { value: 6, label: '六' },
    { value: 7, label: '日' },
  ];

  const syncRepeatVisibility = (): void => {
    const enabled = repeatEnabledInput.checked;
    repeatFields.style.display = enabled ? 'flex' : 'none';
    repeatWeekdaysWrap.style.display =
      enabled && recurrenceConfig.unit === RecurrenceUnit.week ? 'flex' : 'none';

    const endMode = repeatEndModeSelect.value;
    repeatEndDateInput.style.display = endMode === 'date' ? 'block' : 'none';
    repeatEndCountInput.style.display = endMode === 'count' ? 'block' : 'none';
  };

  const renderWeekdays = (): void => {
    repeatWeekdaysWrap.innerHTML = '';
    for (const option of weekdayOptions) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.textContent = option.label;
      const selected = recurrenceConfig.weekdays.has(option.value);
      btn.style.cssText = `
        border-radius:999px;
        width:28px;
        height:28px;
        font-size:11px;
        font-weight:600;
        cursor:pointer;
        background:${selected ? 'var(--tempo-fg)' : 'var(--tempo-bg-muted)'};
        color:${selected ? '#fff' : 'var(--tempo-fg-muted)'};
        border:1px solid ${selected ? 'var(--tempo-fg)' : 'var(--tempo-border-strong)'};
      `;
      btn.addEventListener('click', () => {
        const next = new Set(recurrenceConfig.weekdays);
        if (next.has(option.value)) next.delete(option.value);
        else next.add(option.value);
        recurrenceConfig = { ...recurrenceConfig, weekdays: next };
        renderWeekdays();
      });
      repeatWeekdaysWrap.appendChild(btn);
    }
  };

  const initRecurrenceUi = (): void => {
    const hasRule = hasRecurrence(recurrenceConfig);
    repeatEnabledInput.checked = hasRule;
    repeatIntervalInput.value = `${hasRule ? recurrenceConfig.interval : 1}`;
    repeatUnitSelect.value = hasRule ? recurrenceConfig.unit : RecurrenceUnit.day;

    if (recurrenceConfig.endDate) {
      repeatEndModeSelect.value = 'date';
      repeatEndDateInput.value = toDateInputValue(recurrenceConfig.endDate);
    } else if (recurrenceConfig.occurrenceCount != null) {
      repeatEndModeSelect.value = 'count';
      repeatEndCountInput.value = `${recurrenceConfig.occurrenceCount}`;
    } else {
      repeatEndModeSelect.value = 'never';
    }

    renderWeekdays();
    syncRepeatVisibility();
  };

  repeatEnabledInput.addEventListener('change', syncRepeatVisibility);
  repeatUnitSelect.addEventListener('change', () => {
    recurrenceConfig = {
      ...recurrenceConfig,
      unit: repeatUnitSelect.value as RecurrenceUnit,
    };
    syncRepeatVisibility();
  });
  repeatEndModeSelect.addEventListener('change', syncRepeatVisibility);

  const readRecurrenceFromUi = (): RecurrenceConfig => {
    if (!repeatEnabledInput.checked) return { ...RECURRENCE_NONE };

    const interval = Math.max(
      1,
      Number.parseInt(repeatIntervalInput.value, 10) || 1
    );
    const unit = repeatUnitSelect.value as RecurrenceUnit;
    const endMode = repeatEndModeSelect.value;

    let endDate: Date | null = null;
    let occurrenceCount: number | null = null;
    if (endMode === 'date' && repeatEndDateInput.value) {
      endDate = parseDueDate(repeatEndDateInput.value, '12:00', true);
    } else if (endMode === 'count') {
      occurrenceCount = Math.max(
        1,
        Number.parseInt(repeatEndCountInput.value, 10) || 1
      );
    }

    return {
      interval,
      unit,
      weekdays: recurrenceConfig.weekdays,
      endDate,
      occurrenceCount,
    };
  };

  initRecurrenceUi();

  const priorityOptions: Array<{ value: TaskPriority; label: string }> = [
    { value: TaskPriority.none, label: '无' },
    { value: TaskPriority.p0, label: 'P0' },
    { value: TaskPriority.p1, label: 'P1' },
    { value: TaskPriority.p2, label: 'P2' },
    { value: TaskPriority.p3, label: 'P3' },
  ];

  const renderPriority = (): void => {
    priorityWrap.innerHTML = '';
    for (const option of priorityOptions) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.textContent = option.label;
      btn.style.cssText = `
        border-radius:999px;
        padding:6px 12px;
        font-size:12px;
        font-weight:600;
        cursor:pointer;
        ${priorityStyles(option.value, selectedPriority === option.value)}
      `;
      btn.addEventListener('click', () => {
        selectedPriority = option.value;
        renderPriority();
      });
      priorityWrap.appendChild(btn);
    }
  };

  const tagOptions: Array<{ value: string | null; label: string }> = [
    { value: null, label: '无' },
    { value: TAG_WORK, label: '工作' },
    { value: TAG_LIFE, label: '生活' },
  ];

  const renderTags = (): void => {
    tagWrap.innerHTML = '';
    for (const option of tagOptions) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.textContent = option.label;
      const selected = selectedTag === option.value;
      btn.style.cssText = `
        border-radius:999px;
        padding:6px 12px;
        font-size:12px;
        font-weight:600;
        cursor:pointer;
        background:${selected ? 'var(--tempo-fg)' : 'var(--tempo-bg-muted)'};
        color:${selected ? '#fff' : 'var(--tempo-fg-muted)'};
        border:1px solid ${selected ? 'var(--tempo-fg)' : 'var(--tempo-border-strong)'};
      `;
      btn.addEventListener('click', () => {
        selectedTag = option.value;
        renderTags();
      });
      tagWrap.appendChild(btn);
    }
  };

  const syncTimeVisibility = (): void => {
    timeInput.disabled = allDayInput.checked;
    timeInput.style.opacity = allDayInput.checked ? '0.45' : '1';
  };

  renderPriority();
  renderTags();
  syncTimeVisibility();
  allDayInput.addEventListener('change', syncTimeVisibility);

  (buttons[0] as HTMLButtonElement).addEventListener('click', () => dialog.destroy());

  saveButton.addEventListener('click', async () => {
    const title = titleInput.value.trim();
    if (!title) {
      titleInput.focus();
      return;
    }

    saveButton.disabled = true;
    saveButton.textContent = '保存中…';

    try {
      const dueDate = parseDueDate(
        dateInput.value,
        timeInput.value,
        allDayInput.checked
      );

      const nextRecurrence = readRecurrenceFromUi();
      const recurrenceRule = recurrenceConfigToRRule(nextRecurrence);

      await options.onSubmit({
        title,
        description: descInput.value.trim() || null,
        priority: selectedPriority,
        dueDate,
        isAllDay: allDayInput.checked,
        tag: selectedTag,
        recurrenceRule,
        recurrenceEnd: nextRecurrence.endDate ?? null,
        recurrenceCount: nextRecurrence.occurrenceCount ?? null,
      });
      dialog.destroy();
    } catch (error) {
      saveButton.disabled = false;
      saveButton.textContent = isEdit ? '保存' : '创建';
      window.alert(error instanceof Error ? error.message : String(error));
    }
  });

  titleInput.focus();
}

function escapeAttr(value: string): string {
  return value.replace(/"/g, '&quot;');
}

function escapeText(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}
