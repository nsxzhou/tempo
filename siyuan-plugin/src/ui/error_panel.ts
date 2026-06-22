export function renderErrorPanel(
  container: HTMLElement,
  title: string,
  detail: string
): void {
  container.innerHTML = '';

  const panel = document.createElement('div');
  panel.className = 'tempo-error-panel';
  panel.style.cssText = `
    padding: 24px;
    max-width: 520px;
    margin: 32px auto;
    border: 0.8px solid var(--tempo-border-strong, #ddd);
    border-radius: 12px;
    background: var(--tempo-bg, #fff);
    color: var(--tempo-fg, #111);
    font-family: var(--tempo-font-sans, sans-serif);
  `;

  const heading = document.createElement('h2');
  heading.textContent = title;
  heading.style.cssText = 'margin:0 0 8px;font-size:18px;';

  const body = document.createElement('pre');
  body.textContent = detail;
  body.style.cssText = `
    margin: 0;
    white-space: pre-wrap;
    word-break: break-word;
    font-size: 12px;
    line-height: 1.5;
    color: var(--tempo-p0, #c0392b);
    font-family: var(--tempo-font-mono, monospace);
  `;

  panel.appendChild(heading);
  panel.appendChild(body);
  container.appendChild(panel);
}
