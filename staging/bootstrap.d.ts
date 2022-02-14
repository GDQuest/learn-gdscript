interface GDQuestLib {
  startLoading: () => void;
  displayFailureNotice: (err: Error | string) => void;
  log: Log;
  makeLogger: (title: string) => Console;
  fullScreen: {
    isIt: {
      checkFullScreenElement: () => boolean;
      checkCSSMediaQuery: () => boolean;
      checkWindowMargins: () => boolean;
    };
    toggle: () => void;
  };
  events: {
    onError: Signal;
    onFullScreen: Signal;
    onGodotLoaded: Signal;
    onResize: Signal;
  };
}

declare const GDQUEST_ENVIRONMENT: {
  github_repository: string;
  github_workflow: string;
  github_ref_name: string;
  github_sha: string;
  override_file: string;
  sub_build_path: string;
  watermark: string;
};

interface Signal {
  disconnect: (fn: (...args: any[]) => void) => boolean;
  connect: (fn: (...args: any[]) => void) => () => boolean;
  once: (fn: (...args: any[]) => void) => () => boolean;
  emit: (...args: any[]) => void;
}

interface LogFunction {
  (object: any, msg: string): void;
}

interface LogLine extends Record<string, any> {
  time: number;
  level: number;
  msg: string;
}

interface Log {
  trace: LogFunction;
  debug: LogFunction;
  info: LogFunction;
  warn: LogFunction;
  error: LogFunction;
  fatal: LogFunction;
  display: () => void;
  clear: () => void;
  download: () => void;
  trimIfOverLimit: (maxKiloBytes?: number) => boolean;
  logSystemInfoIfLogIsEmpty: (additionalData?: Record<string, any>) => void;
  get: () => LogLine[];
}
interface GodotEngineInstanceStartGameOptions {
  onProgress: (current: number, total: number) => void;
}

declare class GodotEngineInstance {
  startGame: (options: GodotEngineInstanceStartGameOptions) => Promise<void>;
}

declare const GODOT_CONFIG: {
  canvasResizePolicy: number;
  unloadAfterInit: boolean;
  canvas: HTMLCanvasElement;
  executable: string;
  mainPack: string;
  locale: string;
  args: string[];
  onExecute: (path: string, args: string[]) => void;
  onExit: (status_code: number) => void;
  onProgress: (current: number, total: number) => void;
  onPrint: (...args: any[]) => void;
  onPrintError: (...args: any[]) => void;
};

declare const Engine: {
  new (config: typeof GODOT_CONFIG): GodotEngineInstance;
  isWebGLAvailable: () => boolean;
};

interface Window {
  GDQUEST: GDQuestLib;
}
