// ============================================================
// index.ts — Tempo 思源待办插件入口
// ============================================================

import { openTab, Plugin as SiyuanPlugin } from 'siyuan';
import fontsCss from './theme/fonts.css';
import layoutCss from './theme/layout.css';
import tokensCss from './theme/tokens.css';
import { TAB_TYPE } from './constants';
import { mountTabRoot, refreshTabRoot, unmountTabRoot } from './ui/tab_root';

const STYLE_ID = 'tempo-plugin-styles';

function ensureStyles(): void {
  if (document.getElementById(STYLE_ID)) return;
  const style = document.createElement('style');
  style.id = STYLE_ID;
  style.textContent = `${fontsCss}\n${tokensCss}\n${layoutCss}`;
  document.head.appendChild(style);
}

class TempoPlugin extends SiyuanPlugin {
  onload(): void {
    try {
      ensureStyles();

      this.addTab({
        type: TAB_TYPE,
        init(custom) {
          mountTabRoot(custom.element as HTMLElement);
        },
        update(custom) {
          refreshTabRoot(custom.element as HTMLElement);
        },
        destroy(custom) {
          unmountTabRoot(custom.element as HTMLElement);
        },
        resize(custom) {
          refreshTabRoot(custom.element as HTMLElement);
        },
      });

      this.addTopBar({
        icon: 'iconList',
        title: 'Tempo',
        callback: () => this.openTempoTab(),
      });
    } catch (error) {
      console.error('[Tempo] plugin onload failed:', error);
    }
  }

  private openTempoTab(): void {
    openTab({
      app: this.app,
      custom: {
        title: 'Tempo',
        icon: 'iconList',
        id: `${this.name}${TAB_TYPE}`,
      },
    });
  }
}

// esbuild CJS 打包后 instanceof Plugin 校验可能失败，需显式修复原型链
Object.setPrototypeOf(TempoPlugin.prototype, SiyuanPlugin.prototype);

export default TempoPlugin;
