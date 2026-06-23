declare module 'siyuan' {
  export interface IObject {
    [key: string]: unknown;
  }

  export interface IWebSocketData {
    code: number;
    msg: string;
    data: unknown;
  }

  export interface ITab {
    id: string;
    headElement: HTMLElement;
    panelElement: HTMLElement;
    model: IModel;
    title: string;
    icon: string;
    docIcon: string;
    updateTitle: (title: string) => void;
    pin: () => void;
    unpin: () => void;
    setDocIcon: (icon: string) => void;
    close: () => void;
  }

  export interface IModel {
    type?: string;
    element?: HTMLElement;
  }

  export interface IPluginDockConfig {
    position: string;
    size: { width: number; height: number };
    icon: string;
    title: string;
  }

  export class Plugin {
    name: string;
    app: unknown;
    addTab(options: {
      type: string;
      init: (custom: ITab) => void;
      destroy?: (custom: ITab) => void;
      update?: (custom: ITab) => void;
      beforeDestroy?: (custom: ITab) => void;
      resize?: (custom: ITab) => void;
    }): unknown;
    addTopBar(options: {
      icon: string;
      title: string;
      callback: () => void;
    }): unknown;
    addCommand(options: {
      langKey: string;
      langText?: string;
      hotkey?: string;
      callback?: () => void;
      globalCallback?: () => void;
    }): void;
    addDock(options: {
      config: IPluginDockConfig;
      data: IObject;
      type: string;
      init: (dock: { element: HTMLElement }) => void;
      destroy?: () => void;
    }): void;
  }

  export class Dialog {
    element: HTMLElement;
    constructor(options: {
      title: string;
      content: string;
      width?: string;
      height?: string;
    });
    destroy(): void;
    bindInput?(element: HTMLElement, callback: () => void): void;
  }

  export function getAllTabs(): ITab[];

  export function openTab(options: {
    app: unknown;
    custom: {
      title: string;
      icon: string;
      id: string;
    };
    keepCursor?: boolean;
  }): void;

  export function confirm(
    message: string,
    confirmCallback: () => void,
    cancelCallback?: () => void
  ): void;

  export function fetchSyncPost(
    url: string,
    data?: IObject
  ): Promise<IWebSocketData>;
}
