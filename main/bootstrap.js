//@ts-check
/// <reference path="./bootstrap.d.ts"/>
"use strict";

window.GDQUEST = ((/** @type {GDQuestLib} */ GDQUEST) => {
  const canvas = /** @type {HTMLCanvasElement} */ (
    document.getElementById("canvas")
  );
  const canvasContainer = /** @type {HTMLDivElement} */ (
    document.getElementById("canvas-frame")
  );

  const noOp = () => {};

  const throttle = (callback, limit = 50) => {
    let waiting = false;
    const resetWaiting = () => (waiting = false);
    return (...args) => {
      if (!waiting) {
        callback(...args);
        waiting = true;
        setTimeout(resetWaiting, limit);
      }
    };
  };

  const aspectRatio =
    (maxW = 0, maxH = 0) =>
    (currentWidth = window.innerWidth, currentHeight = window.innerHeight) => {
      const ratioW = currentWidth / maxW;
      const ratioH = currentHeight / maxH;
      const ratio = Math.min(Math.min(ratioW, ratioH), 1);
      const width = maxW * ratio;
      const height = maxH * ratio;
      return { width, height, ratio };
    };

  /**
   * Returns a proxied console that can be turned off and on by appending
   * `?debug` to the URL. Specific modules can be turned on and off by using
   * `?debug=modulea,moduleb`.
   * This is not to be mistaken with the other log module below, which logs
   * _user traces_ from the app to localStorage.
   */
  const makeLogger = (() => {
    const consoleMethods = [
      "log",
      "error",
      "info",
      "warn",
      "assert",
      "trace",
      "table",
    ];

    const fakeLogger = /** @type {Console} */ ({});
    consoleMethods.forEach((k) => (fakeLogger[k] = noOp));

    const params = new URLSearchParams(window.location.search);
    const isDebugMode = params.has("debug");

    if (isDebugMode) {
      document.body.classList.add("debug");
    }

    const modules = (() => {
      const modules = /**@type {Record<string, true>} */ ({});
      if (!isDebugMode) {
        return { app: true };
      }
      const modulesList = params.get("debug").split(",").filter(Boolean);
      if (modulesList.length == 0) {
        return { "*": true };
      }
      modulesList.map((k) => (modules[k] = true));
      return modules;
    })();

    return (/**@type {string} **/ title) => {
      const prepared = [`%c[${title}]`, `color:#5b5bdf;`];
      const logger = /** @type {Console} */ ({});
      if (modules["*"] || modules[title]) {
        consoleMethods.forEach(
          (k) => (logger[k] = (...args) => console[k](...prepared, ...args))
        );
      } else {
        return fakeLogger;
      }
      return logger;
    };
  })();

  GDQUEST.makeLogger = makeLogger;

  const makeSignal = () => {
    const listeners = new Set();
    /**
     * @param {(...args) => void } fn
     * @returns
     */
    const disconnect = (fn) => listeners.delete(fn);
    /**
     * @param {(...args) => void } fn
     */
    const connect = (fn) => {
      listeners.add(fn);
      return () => disconnect(fn);
    };
    const once = (fn) => {
      const wrapped = (...args) => {
        disconnect(wrapped);
        fn(...args);
      };
      return connect(wrapped);
    };
    const emit = (...args) => listeners.forEach((fn) => fn(...args));
    /** @type { Signal } */
    const signal = { disconnect, connect, emit, once };
    return signal;
  };

  GDQUEST.events = {
    onError: makeSignal(),
    onGodotLoaded: makeSignal(),
    onFullScreen: makeSignal(),
    onResize: makeSignal(),
  };

  resize: {
    const onResize = () => {
      const { width, height, ratio } = aspectRatioCanvas();
      canvas.width = width;
      canvas.height = height;
      canvasContainer.style.setProperty(`width`, `${width}px`);
      canvasContainer.style.setProperty(`height`, `${height}px`);
      document.documentElement.style.setProperty("--scale", `${ratio}`);
    };
    const aspectRatioCanvas = aspectRatio(1920, 1080);
    window.addEventListener("resize", throttle(GDQUEST.events.onResize.emit));
    GDQUEST.events.onResize.connect(onResize);
    onResize();
  }

  loadingControl: {
    const debug = makeLogger("loader");
    let is_done = false;

    // these class names get added to document.body
    // css controls what is visible through that mechanism
    const StatusMode = {
      DONE: "mode-done",
      PROGRESS: "mode-progress",
      INDETERMINATE: "mode-indeterminate",
      NOTICE: "mode-notice",
    };

    const allModes = Object.values(StatusMode);

    let currentStatusMode;

    /**
     * Sets a status mode (class name) on the body element.
     * if `is_done` is `true`, the function no-ops
     * @param {string} mode one of the `StatusMode`s
     * @returns
     */
    const setStatusMode = (mode = StatusMode.INDETERMINATE) => {
      if (currentStatusMode === mode || is_done) {
        return;
      }
      document.body.classList.remove(...allModes);
      if (allModes.includes(mode)) {
        document.body.classList.add(mode);
        currentStatusMode = mode;
      } else {
        throw new Error(`Invalid status mode : ${mode}`);
      }
    };

    /**
     * Shows an error to the user
     * @param {Error|string} err
     */
    const displayFailureNotice = (err) => {
      var msg = err instanceof Error ? err.message : err;
      console.error(msg);
      setStatusMode(StatusMode.NOTICE);
      const statusNotice = document.getElementById("notices");
      msg.split("\n").forEach((line) => {
        statusNotice.appendChild(document.createTextNode(line));
        statusNotice.appendChild(document.createElement("br"));
      });
      is_done = true;
    };

    /**
     * Grows the visual loading bar
     * @param {number} percentage
     * @returns
     */
    const displayPercentage = (percentage = 0) =>
      document
        .getElementById("loader")
        .style.setProperty("--progress", percentage * 100 + "%");

    /**
     * Callback used during the loading of the engine and packages
     * @param {number} current the current amount of bytes loaded
     * @param {number} total the total amount of bytes loaded
     */
    const onProgress = (current, total) => {
      if (total > 0) {
        setStatusMode(StatusMode.PROGRESS);
        displayPercentage(current / total);
        if (current === total) {
          onPackageLoaded();
        }
      } else {
        setStatusMode(StatusMode.INDETERMINATE);
      }
    };

    /**
     * Called once Godot loaded everything.
     * All of the operations no-op if `onPackageLoaded` has already been called,
     * so it's safe to call several times.
     */
    const onPackageLoaded = () => {
      displayPercentage(1);
      debug.info("package loaded");
      setTimeout(() => {
        setStatusMode(StatusMode.DONE);
        is_done = true;
        GDQUEST.events.onGodotLoaded.emit();
      }, 200);
    };

    const onPrintError = (/** @type {any[]} */ ...args) => {
      if (args[0] instanceof Error) {
        const { message } = args[0];
        if (/Maximum call stack size exceeded/.test(message)) {
          GDQUEST.events.onError.emit("RECURSIVE");
        }
      } else if (typeof args[0] === "string") {
        if (/Maximum call stack size exceeded/.test(args[0])) {
          GDQUEST.events.onError.emit("RECURSIVE");
        }
      } else {
        debug.error(...args);
      }
    };

    /**
     * Instanciates the engine, starts the package
     */
    const load = () => {
      setStatusMode(StatusMode.INDETERMINATE);
      GODOT_CONFIG.canvasResizePolicy = 0;
      GODOT_CONFIG.onPrintError = onPrintError;
      const engine = new Engine(GODOT_CONFIG);
      engine
        .startGame({ onProgress })
        .then(onPackageLoaded)
        .catch(displayFailureNotice);
    };

    /**
     * Entry point, this is run once the page loads
     */
    const startLoading = () => {
      setStatusMode(StatusMode.INDETERMINATE);

      if (!Engine.isWebGLAvailable()) {
        displayFailureNotice("WebGL not available");
      } else {
        load();
      }
    };

    GDQUEST.startLoading = startLoading;
    GDQUEST.displayFailureNotice = displayFailureNotice;
  }

  mobileHandling: {
    const KEY = "force-mobile";

    const forceAppOnMobile = () => {
      document.body.classList.add(KEY);
      localStorage.setItem(KEY, "true");
    };

    document
      .getElementById("mobile-warning-dismiss-button")
      .addEventListener("click", forceAppOnMobile);

    const currentValue = JSON.parse(localStorage.getItem(KEY) || "false");

    if (currentValue === true) {
      forceAppOnMobile();
    }
  }

  logging: {
    const debug = makeLogger("app");
    const KEY = "log";
    const LEVELS = {
      TRACE: 10,
      DEBUG: 20,
      INFO: 30,
      WARN: 40,
      ERROR: 50,
      FATAL: 60,
    };

    const generateDownloadableFile = (filename = "", text = "") => {
      var element = document.createElement("a");
      element.setAttribute(
        "href",
        "data:text/plain;charset=utf-8," + encodeURIComponent(text)
      );
      element.setAttribute("download", filename);

      element.style.display = "none";
      document.body.appendChild(element);

      element.click();

      document.body.removeChild(element);
    };

    /** @type { Log['get'] } */
    const get = () => JSON.parse(localStorage.getItem(KEY) || "[]");

    const log_lines = get();

    /**
     * Gets the size of a localstorage slot.
     * @param {string} key
     * @returns the size of the data in kilobytes
     */
    const getLocalStorageSizeOf = (key) => () =>
      (((localStorage.getItem(key) || "").length + key.length) * 2) / 1024;

    const getLocalStorageSize = getLocalStorageSizeOf(KEY);

    /** @type { Log['download'] } */
    const download = () =>
      generateDownloadableFile(
        `gdquest-${Date.now()}.log`,
        localStorage.getItem(KEY)
      );

    const makeLogFunction =
      (level = LEVELS.INFO) =>
      /** @type {LogFunction} */
      (anything, msg = "") => {
        if (typeof anything === "string" || typeof anything === "number") {
          msg = String(anything);
          anything = null;
        }

        const time = Date.now();
        /** @type {LogLine} */
        const log_line = { time, level, msg, ...(anything || {}) };
        log_lines.push(log_line);
        localStorage.setItem(KEY, JSON.stringify(log_lines));

        if (level < 30) {
          if (anything) {
            debug.log(msg, anything);
          } else {
            debug.log(msg);
          }
        } else if (level < 40) {
          if (anything) {
            debug.info(msg, anything);
          } else {
            debug.info(msg);
          }
        } else if (level < 50) {
          if (anything) {
            debug.warn(msg, anything);
          } else {
            debug.warn(msg);
          }
        } else {
          if (anything) {
            debug.error(msg, anything);
          } else {
            debug.error(msg);
          }
        }
      };

    /** @type { Log['display'] } */
    const display = () => console.table(get());

    /** @type { Log['clear'] } */
    const clear = () => {
      localStorage.removeItem(KEY);
      console.info("log cleared");
    };

    /** @type { Log['trimIfOverLimit'] } */
    const trimIfOverLimit = (maxKiloBytes = 1000) => {
      let response = false;
      while (getLocalStorageSize() > maxKiloBytes) {
        log_lines.shift();
        localStorage.setItem(KEY, JSON.stringify(log_lines));
        response = true;
      }
      return response;
    };

    const logSystemInfoIfLogIsEmpty = (additionalData = {}) => {
      if (log_lines.length == 0) {
        const { userAgent, vendor } = navigator;
        const { width, height } = screen;
        const { innerHeight, innerWidth } = window;
        const {
          build_date,
          build_date_iso,
          build_date_unix,
          git_branch,
          git_commit,
          version,
        } = GDQUEST_ENVIRONMENT || {};
        const data = {
          userAgent,
          vendor,
          width,
          height,
          innerHeight,
          innerWidth,
          build_date,
          build_date_iso,
          build_date_unix,
          git_branch,
          git_commit,
          version,
          ...additionalData,
        };
        makeLogFunction(LEVELS.TRACE)(data, `INIT`);
      }
    };

    /** @type { Log } */
    // @ts-ignore
    const log = {
      display,
      clear,
      get,
      trimIfOverLimit,
      download,
      logSystemInfoIfLogIsEmpty,
    };
    Object.keys(LEVELS).forEach(
      (key) => (log[key.toLowerCase()] = makeLogFunction(LEVELS[key]))
    );

    GDQUEST.log = log;
  }

  fullscreen: {
    const debug = makeLogger("fullscreen");
    /**
     * Browsers make it exceedingly hard to get that information reliably, so
     * we have to rely on a bunch of different strategies
     */
    const isIt = (() => {
      /**
       * This is an invisible element which changes position when the browser
       * is full screen. We do this through the media query:
       * ```css
       * @media all and (display-mode: fullscreen) {
       *    #fullscreen-detector {
       *      top: 1px;
       *    }
       *  }
       * ```
       */
      const fullScreenPoller = (() => {
        const el = document.createElement("div");
        el.id = "fullscreen-detector";
        document.body.appendChild(el);
        return el;
      })();

      /** check is the element has moved */
      const checkCSSMediaQuery = () => {
        const top = fullScreenPoller.getBoundingClientRect().top > 0;
        return top;
      };

      /** check if browser has borders. Take zoom into account */
      const checkWindowMargins = () => {
        const zoom = window.outerWidth / window.innerWidth;
        const hasMargin =
          Math.abs(window.innerWidth * zoom - screen.width) < 10;
        return hasMargin;
      };

      /** check if some element has been set fullscreen through the JS API */
      const checkFullScreenElement = () => {
        const hasSomeFullScreenElement = document.fullscreenElement !== null;
        return hasSomeFullScreenElement;
      };

      return {
        checkFullScreenElement,
        checkCSSMediaQuery,
        checkWindowMargins,
      };
    })();

    let isFullScreen = false;
    let wasFullScreen = false;

    /** use the JS API to call fullscreen */
    const toggle = () => {
      //debug.info(`will`, isFullScreen ? "exit" : "enter", "fullscreen mode");
      const isItActuallyFullScreen = isIt.checkCSSMediaQuery();
      if (isItActuallyFullScreen !== isFullScreen) {
        debug.error(
          `Mismatch! Expected fullscreen to be ${isFullScreen}, but it is ${isItActuallyFullScreen}.`
        );
        if (isItActuallyFullScreen) {
          debug.error(
            `Cannot exit a fullscreen mode set natively. Bailing out!`
          );
          return;
        } else {
          debug.warn(`Will set our fullscreen now`);
          isFullScreen = false;
        }
      }
      isFullScreen
        ? document.exitFullscreen()
        : document.documentElement.requestFullscreen();
      isFullScreen = !isFullScreen;
    };

    /**
     * Create a button with the proper classes; change class when
     * fullscreen event happens
     */
    const button = (() => {
      const normalClassName = "button-fullscreen";

      const button = document.createElement("button");
      button.classList.add(normalClassName);
      button.addEventListener("click", toggle);

      const label = document.createElement("span");
      label.textContent = "toggle Fullscreen";
      button.appendChild(label);
      return button;
    })();

    /**
     * Only add the button if Godot has loaded
     */
    GDQUEST.events.onGodotLoaded.once(() => {
      canvasContainer.appendChild(button);
    });

    /**
     * Checks if the actual fullscreen state was set through an API
     * If we're _exiting_ fullscreen, then we can't check, but we
     * set `isFullScreen` to `false`.
     * @param {boolean} isItActuallyFullScreen
     */
    const wasItOurFullScreen = (isItActuallyFullScreen) => {
      if (isItActuallyFullScreen) {
        if (isIt.checkFullScreenElement()) {
          debug.log("full screen changed through our button");
        } else {
          // that means fullscreen was set _not_ through our button
          debug.warn("full screen changed through shortcut, hiding the button");
          document.body.classList.add("native-fullscreen");
        }
      } else {
        debug.log("exiting fullscreen");
        isFullScreen = false;
        document.body.classList.remove("native-fullscreen");
      }
    };

    /**
     * @param {Event} evt
     */
    const onFullScreenChange = (evt) => {
      const isItActuallyFullScreen = isIt.checkFullScreenElement();
      if (isItActuallyFullScreen != wasFullScreen) {
        wasFullScreen = isItActuallyFullScreen;
        debug.info(`[ ${evt.type} ]`, `full screen state changed`);
        const wasIt = wasItOurFullScreen(isItActuallyFullScreen);
        GDQUEST.events.onFullScreen.emit(isItActuallyFullScreen, wasIt);
      }
    };

    document.addEventListener("keydown", (event) => {
      if (event.code == `F11`) {
        event.preventDefault();
        button.focus();
        debug.log("Stopped F11");
      }
    });

    /**
     * This is for when using the JS API
     */
    document.addEventListener("fullscreenchange", onFullScreenChange);
    /**
     * This is for buttons, shortcuts, and other methods for setting fullscreen.
     * We could also potentially poll for size after keypresses, but this seems
     * to work well enough
     */
    GDQUEST.events.onResize.connect(onFullScreenChange);

    GDQUEST.fullScreen = { isIt, toggle };
  }

  return GDQUEST;
  // @ts-ignore
})(window.GDQUEST || {});

window.GDQUEST.startLoading();
