declare module 'siyuan' {
  export interface IObject {
    [key: string]: unknown;
  }

  export interface IWebSocketData {
    code: number;
    msg: string;
    data: unknown;
  }

  export interface IDock {
    element: HTMLElement;
  }

  export interface IPluginDockConfig {
    position: string;
    size: { width: number; height: number };
    icon: string;
    title: string;
  }

  export class Plugin {
    name: string;
    addDock(options: {
      config: IPluginDockConfig;
      data: IObject;
      type: string;
      init: (dock: IDock) => void;
      destroy?: () => void;
    }): void;
  }

  export function fetchSyncPost(
    url: string,
    data?: IObject
  ): Promise<IWebSocketData>;
}
