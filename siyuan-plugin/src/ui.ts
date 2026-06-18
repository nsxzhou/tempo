// ============================================================
// ui.ts — 插件面板 UI（绑定状态/配对码输入/扫描按钮/统计）
// ============================================================

import { isPaired, loadAuth, clearAuth, type StoredAuth } from './storage';
import { pairWithCode, PairingError } from './pairing';
import { syncTasks } from './sync';
import {
  getCurrentDocId,
  getChildBlocks,
  extractUncompletedTasks,
  type ScanResult,
} from './scanner';

/** UI 状态 */
type UIState = 'unpaired' | 'paired' | 'pairing' | 'scanning';

/** 插件 UI 面板容器 ID */
const PANEL_ID = 'tempo-sync-panel';

/** 渲染插件面板 */
export function renderPanel(container: HTMLElement): void {
  container.innerHTML = '';
  container.id = PANEL_ID;

  const paired = isPaired();
  renderState(container, paired ? 'paired' : 'unpaired');
}

/** 根据状态渲染 UI */
function renderState(container: HTMLElement, state: UIState): void {
  container.innerHTML = '';

  const wrapper = document.createElement('div');
  wrapper.style.padding = '16px';
  wrapper.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';

  switch (state) {
    case 'unpaired':
      renderUnpairedUI(wrapper);
      break;
    case 'paired':
      renderPairedUI(wrapper);
      break;
    case 'pairing':
      renderPairingUI(wrapper);
      break;
    case 'scanning':
      renderScanningUI(wrapper);
      break;
  }

  container.appendChild(wrapper);
}

/** 未绑定状态 UI */
function renderUnpairedUI(container: HTMLElement): void {
  const title = document.createElement('h3');
  title.textContent = '绑定 Tempo 账号';
  title.style.margin = '0 0 12px 0';
  container.appendChild(title);

  const hint = document.createElement('p');
  hint.textContent = '请在 Tempo App 中打开：设置 → 思源同步 → 生成配对码';
  hint.style.color = '#666';
  hint.style.fontSize = '14px';
  hint.style.marginBottom = '16px';
  container.appendChild(hint);

  // 配对码输入
  const inputLabel = document.createElement('label');
  inputLabel.textContent = '输入 6 位配对码：';
  inputLabel.style.display = 'block';
  inputLabel.style.marginBottom = '8px';
  container.appendChild(inputLabel);

  const input = document.createElement('input');
  input.type = 'text';
  input.maxLength = 6;
  input.placeholder = '______';
  input.style.width = '100%';
  input.style.padding = '8px 12px';
  input.style.fontSize = '20px';
  input.style.letterSpacing = '8px';
  input.style.textAlign = 'center';
  input.style.boxSizing = 'border-box';
  input.style.borderRadius = '8px';
  input.style.border = '1px solid #ddd';
  container.appendChild(input);

  // 错误提示
  const errorDiv = document.createElement('div');
  errorDiv.style.color = '#dc2626';
  errorDiv.style.fontSize = '13px';
  errorDiv.style.marginTop = '8px';
  errorDiv.style.minHeight = '18px';
  container.appendChild(errorDiv);

  // 绑定按钮
  const button = document.createElement('button');
  button.textContent = '绑定';
  button.style.width = '100%';
  button.style.padding = '10px';
  button.style.marginTop = '16px';
  button.style.fontSize = '15px';
  button.style.backgroundColor = '#4F46E5';
  button.style.color = 'white';
  button.style.border = 'none';
  button.style.borderRadius = '8px';
  button.style.cursor = 'pointer';
  container.appendChild(button);

  const note = document.createElement('p');
  note.textContent = '配对码 5 分钟内有效';
  note.style.color = '#999';
  note.style.fontSize = '12px';
  note.style.textAlign = 'center';
  note.style.marginTop = '12px';
  container.appendChild(note);

  // 绑定事件
  button.onclick = async () => {
    const code = input.value.trim();
    if (!/^\d{6}$/.test(code)) {
      errorDiv.textContent = '请输入 6 位数字配对码';
      return;
    }

    button.disabled = true;
    button.textContent = '绑定中...';
    errorDiv.textContent = '';

    try {
      await pairWithCode(code);
      // 绑定成功，刷新 UI
      renderState(container.parentElement!, 'paired');
    } catch (error) {
      button.disabled = false;
      button.textContent = '绑定';
      if (error instanceof PairingError) {
        errorDiv.textContent = error.message;
      } else {
        errorDiv.textContent = `绑定失败: ${error}`;
      }
    }
  };
}

/** 已绑定状态 UI */
function renderPairedUI(container: HTMLElement): void {
  const auth = loadAuth();

  // 标题
  const title = document.createElement('h3');
  title.textContent = 'Tempo 任务同步';
  title.style.margin = '0 0 12px 0';
  container.appendChild(title);

  // 绑定状态
  const statusDiv = document.createElement('div');
  statusDiv.style.padding = '12px';
  statusDiv.style.backgroundColor = '#ecfdf5';
  statusDiv.style.borderRadius = '8px';
  statusDiv.style.marginBottom = '16px';

  const statusText = document.createElement('div');
  statusText.innerHTML = `✅ 已绑定 <strong>${auth?.user_email || '未知'}</strong>`;
  statusDiv.appendChild(statusText);
  container.appendChild(statusDiv);

  // 扫描按钮
  const scanButton = document.createElement('button');
  scanButton.textContent = '扫描当前文档任务';
  scanButton.style.width = '100%';
  scanButton.style.padding = '12px';
  scanButton.style.fontSize = '15px';
  scanButton.style.backgroundColor = '#4F46E5';
  scanButton.style.color = 'white';
  scanButton.style.border = 'none';
  scanButton.style.borderRadius = '8px';
  scanButton.style.cursor = 'pointer';
  scanButton.style.marginBottom = '8px';
  container.appendChild(scanButton);

  // 扫描结果区域
  const resultDiv = document.createElement('div');
  resultDiv.style.marginTop = '12px';
  container.appendChild(resultDiv);

  // 上次同步时间
  const lastSync = document.createElement('p');
  lastSync.textContent = `上次同步: ${auth ? new Date(auth.stored_at).toLocaleString('zh-CN') : '未知'}`;
  lastSync.style.color = '#999';
  lastSync.style.fontSize = '12px';
  lastSync.style.marginTop = '16px';
  container.appendChild(lastSync);

  // 解绑按钮
  const unbindButton = document.createElement('button');
  unbindButton.textContent = '解绑';
  unbindButton.style.width = '100%';
  unbindButton.style.padding = '8px';
  unbindButton.style.marginTop = '8px';
  unbindButton.style.fontSize = '14px';
  unbindButton.style.backgroundColor = '#f3f4f6';
  unbindButton.style.color = '#dc2626';
  unbindButton.style.border = '1px solid #e5e7eb';
  unbindButton.style.borderRadius = '8px';
  unbindButton.style.cursor = 'pointer';
  container.appendChild(unbindButton);

  // 扫描事件
  scanButton.onclick = async () => {
    scanButton.disabled = true;
    scanButton.textContent = '扫描中...';
    resultDiv.innerHTML = '';

    try {
      const docId = await getCurrentDocId();
      if (!docId) {
        throw new Error('无法获取当前文档，请确保已打开一个文档');
      }

      const blocks = await getChildBlocks(docId);
      const tasks = extractUncompletedTasks(blocks);

      if (tasks.length === 0) {
        resultDiv.innerHTML = '<p style="color:#999;">未找到未完成的任务块</p>';
      } else {
        resultDiv.innerHTML = `<p>找到 ${tasks.length} 个未完成任务块，正在导入...</p>`;
        const result = await syncTasks(tasks);
        renderScanResult(resultDiv, result);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      resultDiv.innerHTML = `<p style="color:#dc2626;">扫描失败: ${message}</p>`;
    } finally {
      scanButton.disabled = false;
      scanButton.textContent = '扫描当前文档任务';
    }
  };

  // 解绑事件
  unbindButton.onclick = () => {
    if (confirm('确定要解绑 Tempo 账号吗？')) {
      clearAuth();
      renderState(container.parentElement!, 'unpaired');
    }
  };
}

/** 渲染扫描结果 */
function renderScanResult(container: HTMLElement, result: ScanResult): void {
  container.innerHTML = '';

  const summary = document.createElement('div');
  summary.style.padding = '12px';
  summary.style.backgroundColor = '#f0fdf4';
  summary.style.borderRadius = '8px';
  summary.innerHTML = `
    <strong>扫描完成</strong><br>
    已导入 ${result.imported} 个，跳过 ${result.skipped} 个
  `;
  container.appendChild(summary);

  if (result.errors.length > 0) {
    const errorList = document.createElement('div');
    errorList.style.marginTop = '8px';
    errorList.style.color = '#dc2626';
    errorList.style.fontSize = '13px';
    errorList.innerHTML = `<strong>错误 (${result.errors.length}):</strong><br>${result.errors.join('<br>')}`;
    container.appendChild(errorList);
  }
}

/** 配对中状态 UI */
function renderPairingUI(container: HTMLElement): void {
  container.innerHTML = '<p>配对中...</p>';
}

/** 扫描中状态 UI */
function renderScanningUI(container: HTMLElement): void {
  container.innerHTML = '<p>扫描中...</p>';
}
