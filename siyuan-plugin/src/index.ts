// ============================================================
// index.ts — 思源 Petal 插件入口
// ============================================================

import { Plugin } from 'siyuan';
import { renderPanel } from './ui';

export default class TempoSyncPlugin extends Plugin {
  private panelElement: HTMLElement | null = null;

  onload(): void {
    this.addDock({
      config: {
        position: 'RightBottom',
        size: { width: 320, height: 420 },
        icon: 'iconHeart',
        title: 'Tempo 同步',
      },
      data: {},
      type: 'custom',
      init: (dock) => {
        this.panelElement = dock.element;
        renderPanel(dock.element);
      },
      destroy: () => {
        this.panelElement = null;
      },
    });
  }

  onunload(): void {
    this.panelElement = null;
  }
}
