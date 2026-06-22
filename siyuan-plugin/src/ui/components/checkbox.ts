export function createCheckbox(options: {
  checked: boolean;
  onToggle: () => void;
}): HTMLButtonElement {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'tempo-checkbox';
  button.setAttribute('aria-label', options.checked ? '标记未完成' : '标记完成');
  button.style.cssText = `
    width: 18px;
    height: 18px;
    border-radius: 999px;
    border: 1.2px solid ${options.checked ? 'var(--tempo-fg)' : 'var(--tempo-border-emphasis)'};
    background: ${options.checked ? 'var(--tempo-fg)' : 'transparent'};
    display: inline-flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    padding: 0;
    flex-shrink: 0;
    transition: all var(--tempo-duration-fast) ease;
  `;

  if (options.checked) {
    button.innerHTML = `<svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M2 5.2L4.2 7.4L8 3.2" stroke="#fff" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
  }

  button.addEventListener('click', (event) => {
    event.stopPropagation();
    options.onToggle();
  });

  return button;
}
