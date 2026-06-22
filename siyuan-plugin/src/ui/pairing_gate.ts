import { PAIRING_CODE_LENGTH } from '../constants';
import { pairWithCode, PairingError } from '../pairing';

export function renderPairingGate(
  container: HTMLElement,
  onPaired: () => void
): void {
  container.innerHTML = '';

  const wrap = document.createElement('div');
  wrap.className = 'tempo-pairing-wrap';

  const split = document.createElement('div');
  split.className = 'tempo-pairing-split';

  const card = document.createElement('div');
  card.className = 'tempo-pairing-card';

  const title = document.createElement('h2');
  title.textContent = '连接 Tempo';
  title.style.cssText = `
    margin: 0 0 8px;
    font-size: 24px;
    font-weight: 600;
    letter-spacing: -0.4px;
    color: var(--tempo-fg);
  `;

  const hint = document.createElement('p');
  hint.textContent =
    '在 Tempo App：我的 → 思源外部笔记 Petal 连接 → 生成配对码，然后在此输入 6 位码。';
  hint.style.cssText = `
    margin: 0 0 24px;
    font-size: 14px;
    line-height: 1.6;
    color: var(--tempo-fg-muted);
  `;

  const label = document.createElement('label');
  label.textContent = '输入 6 位配对码';
  label.style.cssText = `
    display: block;
    margin-bottom: 8px;
    font-size: 12px;
    color: var(--tempo-fg-muted);
    font-weight: 500;
  `;

  const input = document.createElement('input');
  input.type = 'text';
  input.inputMode = 'numeric';
  input.maxLength = PAIRING_CODE_LENGTH;
  input.placeholder = '• • • • • •';
  input.style.cssText = `
    width: 100%;
    box-sizing: border-box;
    padding: 14px 16px;
    font-family: var(--tempo-font-mono);
    font-size: 28px;
    letter-spacing: 10px;
    text-align: center;
    border: 0.8px solid var(--tempo-border-strong);
    border-radius: var(--tempo-radius-md);
    background: var(--tempo-bg-muted);
    color: var(--tempo-fg);
  `;

  const errorDiv = document.createElement('div');
  errorDiv.style.cssText = `
    min-height: 18px;
    margin-top: 10px;
    font-size: 13px;
    color: var(--tempo-p0);
  `;

  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = '绑定';
  button.style.cssText = `
    width: 100%;
    margin-top: 20px;
    padding: 12px 16px;
    border: none;
    border-radius: var(--tempo-radius-md);
    background: var(--tempo-fg);
    color: #fff;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
  `;

  const note = document.createElement('p');
  note.textContent = '配对码 5 分钟内有效';
  note.style.cssText = `
    margin: 14px 0 0;
    text-align: center;
    font-size: 12px;
    color: var(--tempo-fg-subtle);
    font-family: var(--tempo-font-mono);
  `;

  button.addEventListener('click', async () => {
    const code = input.value.trim();
    if (!/^\d{6}$/.test(code)) {
      errorDiv.textContent = '请输入 6 位数字配对码';
      return;
    }

    button.disabled = true;
    button.textContent = '绑定中…';
    errorDiv.textContent = '';

    try {
      await pairWithCode(code);
      onPaired();
    } catch (error) {
      button.disabled = false;
      button.textContent = '绑定';
      errorDiv.textContent =
        error instanceof PairingError ? error.message : `绑定失败: ${error}`;
    }
  });

  input.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      button.click();
    }
  });

  card.appendChild(title);
  card.appendChild(hint);
  card.appendChild(label);
  card.appendChild(input);
  card.appendChild(errorDiv);
  card.appendChild(button);
  card.appendChild(note);

  const aside = document.createElement('div');
  aside.className = 'tempo-pairing-aside';

  const asideTitle = document.createElement('h3');
  asideTitle.className = 'tempo-pairing-aside-title';
  asideTitle.textContent = '在思源里使用 Tempo 待办';

  const steps = document.createElement('ol');
  steps.className = 'tempo-pairing-steps';
  steps.innerHTML = `
    <li>打开手机 Tempo App，进入「我的」</li>
    <li>点击「思源外部笔记 Petal 连接」</li>
    <li>生成 6 位配对码并在左侧输入</li>
    <li>绑定后即可在思源中管理待办与日历</li>
  `;

  const asideNote = document.createElement('p');
  asideNote.textContent = '配对成功后，待办与日历数据会与手机 App 云端同步。';
  asideNote.style.cssText = `
    margin: 16px 0 0;
    font-size: 13px;
    line-height: 1.7;
    color: var(--tempo-fg-subtle);
  `;

  aside.appendChild(asideTitle);
  aside.appendChild(steps);
  aside.appendChild(asideNote);

  split.appendChild(card);
  split.appendChild(aside);
  wrap.appendChild(split);
  container.appendChild(wrap);

  input.focus();
}
