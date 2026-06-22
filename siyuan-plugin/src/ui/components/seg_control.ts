export interface SegOption<T extends string> {
  value: T;
  label: string;
  count?: number;
}

export function createSegmentedControl<T extends string>(options: {
  items: SegOption<T>[];
  value: T;
  onChange: (value: T) => void;
}): HTMLElement {
  const wrap = document.createElement('div');
  wrap.style.cssText = `
    display: flex;
    gap: 4px;
    padding: 4px;
    background: var(--tempo-bg-muted);
    border-radius: var(--tempo-radius-md);
    border: 0.8px solid var(--tempo-border-subtle);
  `;

  for (const item of options.items) {
    const selected = item.value === options.value;
    const button = document.createElement('button');
    button.type = 'button';
    button.style.cssText = `
      flex: 1;
      border: none;
      background: ${selected ? 'var(--tempo-bg)' : 'transparent'};
      color: ${selected ? 'var(--tempo-fg)' : 'var(--tempo-fg-muted)'};
      border-radius: calc(var(--tempo-radius-md) - 2px);
      padding: 8px 10px;
      font-size: 13px;
      font-weight: ${selected ? '600' : '500'};
      cursor: pointer;
      box-shadow: ${selected ? 'var(--tempo-shadow-sm)' : 'none'};
      transition: all var(--tempo-duration-fast) ease;
    `;
    button.innerHTML =
      item.count === undefined
        ? item.label
        : `${item.label}<span style="margin-left:6px;font-family:var(--tempo-font-mono);font-size:11px;color:var(--tempo-fg-subtle);">${item.count}</span>`;
    button.addEventListener('click', () => options.onChange(item.value));
    wrap.appendChild(button);
  }

  return wrap;
}
