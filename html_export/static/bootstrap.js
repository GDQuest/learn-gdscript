((LIB = {}) => {
  loadingControl: {
    let is_initializing = true;

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
     * Sets a status mode (class name) on the body element
     * @param {string} mode one of the `StatusMode`s
     * @returns
     */
    const setStatusMode = (mode = StatusMode.INDETERMINATE) => {
      if (currentStatusMode === mode || !is_initializing) {
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
      var msg = err.message || err;
      console.error(msg);
      setStatusMode(StatusMode.NOTICE);
      text.split("\n").forEach((line) => {
        statusNotice.appendChild(document.createTextNode(line));
        statusNotice.appendChild(document.createElement("br"));
      });
      is_initializing = false;
    };

    /**
     * Callback used during the loading of the engine and packages
     * @param {number} current the current amount of bytes loaded
     * @param {number} total the total amount of bytes loaded
     */
    const onProgress = (current, total) => {
      if (total > 0) {
        setStatusMode(StatusMode.PROGRESS);
        document
          .getElementById("loader")
          .style.setProperty("--progress", (current / total) * 100 + "%");
      } else {
        setStatusMode(StatusMode.INDETERMINATE);
      }
    };

    const onPackageLoaded = () => {
      setStatusMode(StatusMode.DONE);
      is_initializing = false;
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
    const start = () => {
      setStatusMode(StatusMode.INDETERMINATE);

      if (!Engine.isWebGLAvailable()) {
        displayFailureNotice("WebGL not available");
      } else {
        load();
      }
    };
    LIB.startLoading = start;
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

  clipboard: {
    const copyTextToClipboard = (text) => {
      const textArea = document.createElement("textarea");
      textArea.className = "copy-text";
      textArea.value = text;
      document.body.appendChild(textArea);
      textArea.focus();
      textArea.select();

      try {
        var isSuccessful = document.execCommand("copy");
        console.log("Copying text command was successful?", isSuccessful);
      } catch (err) {
        console.log("unable to copy");
      }
      document.body.removeChild(textArea);
    };

    window.addEventListener("paste", (event) => {
      const paste = (event.clipboardData || window.clipboardData).getData(
        "text"
      );
      console.log("paste action initiated", paste);
    });
    LIB.copyTextToClipboard = copyTextToClipboard;
  }
})((window.GDQUEST = {}));

GDQUEST.startLoading();
