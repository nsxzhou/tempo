// ============================================================
// index.ts — 思源 Petal 插件入口
// 注册 UI、事件、生命周期
// ============================================================

import { renderPanel } from './ui';
import { isPaired } from './storage';

/**
 * 思源 Petal 插件入口。
 *
 * 生命周期:
 * 1. onload: 初始化 UI 面板
 * 2. onunload: 清理资源
 */
export default class TempoSyncPlugin {
  private container: HTMLElement | null = null;

  /** 插件加载 */
  onload(container: HTMLElement): void {
    this.container = container;
    renderPanel(container);

    // 监听存储变化（多窗口同步）
    window.addEventListener('storage', this.onStorageChange);
  }

  /** 插件卸载 */
  onunload(): void {
    window.removeEventListener('storage', this.onStorageChange);
    this.container = null;
  }

  /** localStorage 变化回调（解绑/绑定时刷新 UI） */
  private onStorageChange = (event: StorageEvent): void => {
    if (event.key === 'tempo_siyuan_auth' && this.container) {
      renderPanel(this.container);
    }
  };

  /** 获取当前绑定状态 */
  get isPaired(): boolean {
    return isPaired();
  }
}

// 思源 Petal 插件注册（全局接口）
declare global {
  interface Window {
    tempoSyncPlugin?: TempoSyncPlugin;
  }
}

// 自动初始化（思源 WebView 环境中执行）
if (typeof window !== 'undefined') {
  const plugin = new TempoSyncPlugin();
  window.tempoSyncPlugin = plugin;

  // 思源插件容器约定: 监听 DOMContentLoaded 后查找挂载点
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      const container = document.getElementById('tempo-plugin-container');
      if (container) {
        plugin.onload(container);
      }
    });
  } else {
    const container = document.getElementById('tempo-plugin-container');
    if (container) {
      plugin.onload(container);
    }
  }
}

export { TempoSyncPlugin };
