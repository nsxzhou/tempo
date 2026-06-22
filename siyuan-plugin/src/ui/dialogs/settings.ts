import { Dialog, confirm } from 'siyuan';
import { PLUGIN_VERSION } from '../../config';
import { resetClient } from '../../api';
import { reportUnpaired } from '../../binding';
import { resetListCache } from '../../data/list_repository';
import { clearAuth, loadAuth } from '../../storage';

export function openSettingsDialog(options: { onUnbind: () => void }): void {
  const auth = loadAuth();

  const dialog = new Dialog({
    title: '账号与连接',
    content: `<div class="b3-dialog__content tempo-dialog-inner" style="font-family:var(--tempo-font-sans);">
      <div style="padding:12px;border:0.8px solid var(--tempo-border-strong);border-radius:var(--tempo-radius-md);background:var(--tempo-bg-subtle);">
        <div style="font-size:12px;color:var(--tempo-fg-muted);margin-bottom:4px;">已绑定账号</div>
        <div style="font-family:var(--tempo-font-mono);font-size:14px;color:var(--tempo-fg);">${auth?.user_email ?? '未知'}</div>
      </div>
      <div style="height:12px"></div>
      <div style="font-size:12px;color:var(--tempo-fg-subtle);font-family:var(--tempo-font-mono);">插件版本 v${PLUGIN_VERSION}</div>
    </div>
    <div class="b3-dialog__action">
      <button class="b3-button b3-button--cancel">关闭</button>
      <div class="fn__space"></div>
      <button class="b3-button b3-button--text" id="tempo-unbind" style="color:var(--tempo-p0);">解绑</button>
    </div>`,
    width: '420px',
  });

  const buttons = dialog.element.querySelectorAll('.b3-button');
  (buttons[0] as HTMLButtonElement).addEventListener('click', () => dialog.destroy());

  const unbindButton = dialog.element.querySelector('#tempo-unbind') as HTMLButtonElement;
  unbindButton.addEventListener('click', () => {
    confirm(
      '确定要解绑 Tempo 账号吗？解绑后需重新输入配对码。',
      () => {
        void (async () => {
          await reportUnpaired();
          clearAuth();
          resetClient();
          resetListCache();
          dialog.destroy();
          options.onUnbind();
        })();
      },
      () => undefined
    );
  });
}
