//@ts-check
/// <reference path="./bootstrap.d.ts"/>
"use strict";

window.GDQUEST = ((/** @type {GDQuestLib} */ GDQUEST) => {
  loadingControl: {
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
        console.info("loading...", total);
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
      setTimeout(() => {
        setStatusMode(StatusMode.DONE);
        is_done = true;
      }, 200);
    };

    /**
     * Instanciates the engine, starts the package
     */
    const load = () => {
      setStatusMode(StatusMode.INDETERMINATE);
      GODOT_CONFIG.canvasResizePolicy = 0;
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
            console.log(msg, anything);
          } else {
            console.log(msg);
          }
        }
        if (level < 40) {
          if (anything) {
            console.info(msg, anything);
          } else {
            console.info(msg);
          }
        } else if (level < 50) {
          if (anything) {
            console.warn(msg, anything);
          } else {
            console.warn(msg);
          }
        } else {
          if (anything) {
            console.error(msg, anything);
          } else {
            console.error(msg);
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
      while (getLocalStorageSize() > maxKiloBytes) {
        log_lines.shift();
        localStorage.setItem(KEY, JSON.stringify(log_lines));
      }
    };

    /** @type { Log } */
    // @ts-ignore
    const log = { display, clear, get, trimIfOverLimit, download };
    Object.keys(LEVELS).forEach(
      (key) => (log[key.toLowerCase()] = makeLogFunction(LEVELS[key]))
    );

    GDQUEST.log = log;
  }

  return GDQUEST;
  // @ts-ignore
})(window.GDQUEST || {});

window.GDQUEST.startLoading();
