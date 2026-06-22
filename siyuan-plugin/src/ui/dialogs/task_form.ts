import { Dialog } from 'siyuan';
import { Task, TaskPriority } from '../../models/task';
import { TAG_LIFE, TAG_WORK } from '../../constants';
import {
  parseDueDate,
  toDateInputValue,
  toTimeInputValue,
} from '../../utils/date_filter';
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
    border:0.8px solid var(--tempo-border-strong);
    border-radius:var(--tempo-radius-md);
    padding:10px 12px;
    font-size:14px;
    font-family:var(--tempo-font-sans);
    background:var(--tempo-bg);
    color:var(--tempo-fg);
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
      ${fieldLabel('分类')}
      <div id="tempo-tag" style="display:flex;gap:8px;flex-wrap:wrap;"></div>
    </div>
    <div class="b3-dialog__action">
      <button class="b3-button b3-button--cancel">取消</button>
      <div class="fn__space"></div>
      <button class="b3-button b3-button--text" id="tempo-save">${isEdit ? '保存' : '创建'}</button>
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
  const buttons = dialog.element.querySelectorAll('.b3-button');
  const saveButton = dialog.element.querySelector('#tempo-save') as HTMLButtonElement;

  let selectedPriority = task?.priority ?? TaskPriority.none;
  let selectedTag: string | null = task?.tag ?? null;

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

      await options.onSubmit({
        title,
        description: descInput.value.trim() || null,
        priority: selectedPriority,
        dueDate,
        isAllDay: allDayInput.checked,
        tag: selectedTag,
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
