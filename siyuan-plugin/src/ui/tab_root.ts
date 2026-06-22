import { initClient } from '../api';
import { TaskStore } from '../data/task_store';
import { isPaired, loadAuth } from '../storage';
import { renderAppShell } from './app_shell';
import { renderErrorPanel } from './error_panel';
import { renderPairingGate } from './pairing_gate';

interface TabMount {
  cleanup: () => void;
  store: TaskStore | null;
}

const mounts = new WeakMap<HTMLElement, TabMount>();

function renderLoading(element: HTMLElement): void {
  element.innerHTML = `
    <div class="tempo-loading-state" style="padding:32px;text-align:center;color:var(--tempo-fg-muted,#666);">
      正在加载 Tempo…
    </div>
  `;
}

export function mountTabRoot(element: HTMLElement): void {
  try {
    element.className = 'tempo-tab-root';
    renderTab(element);
  } catch (error) {
    renderErrorPanel(
      element,
      'Tempo 标签页初始化失败',
      error instanceof Error ? error.message : String(error)
    );
  }
}

export function unmountTabRoot(element: HTMLElement): void {
  const mount = mounts.get(element);
  mount?.cleanup();
  mounts.delete(element);
}

function renderTab(element: HTMLElement): void {
  const previous = mounts.get(element);
  previous?.cleanup();
  element.innerHTML = '';

  if (!isPaired()) {
    renderPairingGate(element, () => renderTab(element));
    mounts.set(element, { cleanup: () => undefined, store: null });
    return;
  }

  renderLoading(element);

  const auth = loadAuth();
  if (auth) {
    initClient(auth);
  }

  const store = new TaskStore();
  let cleanupShell: (() => void) | null = null;

  const onFocus = (): void => {
    void store.refresh();
  };

  element.addEventListener('tempo-tab-focus', onFocus);

  void store
    .init()
    .then(() => {
      try {
        cleanupShell = renderAppShell(element, store, {
          onUnbind: () => renderTab(element),
        });
      } catch (error) {
        renderErrorPanel(
          element,
          'Tempo 界面渲染失败',
          error instanceof Error ? error.message : String(error)
        );
      }
    })
    .catch((error) => {
      renderErrorPanel(
        element,
        'Tempo 数据加载失败',
        error instanceof Error ? error.message : String(error)
      );
    });

  const cleanup = (): void => {
    element.removeEventListener('tempo-tab-focus', onFocus);
    cleanupShell?.();
    store.destroy();
  };

  mounts.set(element, { cleanup, store });
}

export function refreshTabRoot(element: HTMLElement): void {
  element.dispatchEvent(new CustomEvent('tempo-tab-focus'));
}
