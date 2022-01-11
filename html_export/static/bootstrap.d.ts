interface GDQuestLib {
  startLoading: () => void;
  displayFailureNotice: (err: Error | string) => void;
  log: Log;
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
  trimIfOverLimit: (maxKiloBytes?: number) => void;
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
};

declare const Engine: {
  new (config: typeof GODOT_CONFIG): GodotEngineInstance;
  isWebGLAvailable: () => boolean;
};

interface Window {
  GDQUEST: GDQuestLib;
}
