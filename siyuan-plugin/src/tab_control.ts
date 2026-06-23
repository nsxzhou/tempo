import { getAllTabs } from 'siyuan';

import { PLUGIN_NAME, TAB_MODEL_TYPE } from './constants';

function isTempoTab(tab: ReturnType<typeof getAllTabs>[number]): boolean {
  const model = tab.model as { type?: string } | undefined;
  if (model?.type === TAB_MODEL_TYPE) {
    return true;
  }

  const raw = tab.headElement?.getAttribute('data-initdata');
  if (!raw) {
    return tab.title === 'Tempo';
  }

  try {
    const init = JSON.parse(raw) as {
      instance?: string;
      customModelType?: string;
    };
    return (
      init.instance === 'Custom' && init.customModelType === TAB_MODEL_TYPE
    );
  } catch {
    return tab.title === 'Tempo';
  }
}

/** 关闭当前窗口中所有 Tempo 自定义页签。 */
export function closeTempoTabs(): number {
  const tabs = getAllTabs().filter(isTempoTab);
  for (const tab of tabs) {
    try {
      tab.close();
    } catch (error) {
      console.warn(`[${PLUGIN_NAME}] close tab failed:`, error);
    }
  }
  return tabs.length;
}
