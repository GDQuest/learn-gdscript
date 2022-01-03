interface GDQuestLib {
  startLoading: () => void;
  displayFailureNotice: (err: Error | string) => void;
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
