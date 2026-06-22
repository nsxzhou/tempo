import { TaskPriority } from '../../models/task';

export type PillBadgeKind = 'p0' | 'p1' | 'p2' | 'p3' | 'success' | 'neutral';

const styles: Record<PillBadgeKind, [string, string, string]> = {
  p0: ['var(--tempo-p0-bg)', 'var(--tempo-p0)', 'var(--tempo-p0-border)'],
  p1: ['var(--tempo-p1-bg)', 'var(--tempo-p1)', 'var(--tempo-p1-border)'],
  p2: ['var(--tempo-p2-bg)', 'var(--tempo-p2)', 'var(--tempo-p2-border)'],
  p3: ['var(--tempo-p3-bg)', 'var(--tempo-p3)', 'var(--tempo-p3-border)'],
  success: ['var(--tempo-success-bg)', 'var(--tempo-success)', 'var(--tempo-success-border)'],
  neutral: ['var(--tempo-bg-muted)', 'var(--tempo-fg-muted)', 'var(--tempo-border-strong)'],
};

export function priorityBadgeKind(priority: TaskPriority): PillBadgeKind {
  switch (priority) {
    case TaskPriority.p0:
      return 'p0';
    case TaskPriority.p1:
      return 'p1';
    case TaskPriority.p2:
      return 'p2';
    case TaskPriority.p3:
      return 'p3';
    default:
      return 'neutral';
  }
}

export function createPillBadge(label: string, kind: PillBadgeKind): HTMLSpanElement {
  const [bg, fg, border] = styles[kind];
  const badge = document.createElement('span');
  badge.textContent = label;
  badge.style.cssText = `
    display: inline-flex;
    align-items: center;
    padding: 2px 6px;
    border-radius: 999px;
    font-size: 10px;
    font-weight: 600;
    background: ${bg};
    color: ${fg};
    border: 0.8px solid ${border};
  `;
  return badge;
}
