export interface BentoCardOptions {
  label: string;
  value: string;
  unit: string;
  selected: boolean;
  dotColor: string;
  dotPulse?: boolean;
  errorTone?: boolean;
  onTap: () => void;
}

export function createBentoCard(options: BentoCardOptions): HTMLButtonElement {
  const card = document.createElement('button');
  card.type = 'button';
  card.className = 'tempo-bento-card';
  card.style.cssText = `
    border: 0.8px solid ${options.selected ? 'var(--tempo-fg)' : 'var(--tempo-border-strong)'};
    background: ${options.selected ? 'var(--tempo-bg-subtle)' : 'var(--tempo-bg)'};
    border-radius: var(--tempo-radius-lg);
    padding: 14px 16px;
    text-align: left;
    cursor: pointer;
    box-shadow: ${options.selected ? 'none' : 'var(--tempo-shadow-sm)'};
    transition: border-color var(--tempo-duration-fast) ease, background var(--tempo-duration-fast) ease;
    min-height: 88px;
  `;

  const dotStyle = options.dotPulse
    ? `background:${options.dotColor};box-shadow:0 0 0 4px ${options.errorTone ? 'rgba(220,38,38,0.12)' : 'rgba(0,0,0,0.06)'};`
    : `background:${options.dotColor};`;

  card.innerHTML = `
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:10px;">
      <span style="width:6px;height:6px;border-radius:999px;display:inline-block;${dotStyle}"></span>
      <span style="font-size:12px;color:var(--tempo-fg-muted);font-weight:500;">${options.label}</span>
    </div>
    <div style="display:flex;align-items:baseline;gap:6px;">
      <span style="font-family:var(--tempo-font-mono);font-size:28px;line-height:1;font-weight:500;color:${options.errorTone ? 'var(--tempo-p0)' : 'var(--tempo-fg)'};">${options.value}</span>
      <span style="font-size:12px;color:var(--tempo-fg-subtle);">${options.unit}</span>
    </div>
  `;

  card.addEventListener('click', options.onTap);
  return card;
}
