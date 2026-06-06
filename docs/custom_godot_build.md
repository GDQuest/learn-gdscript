# Using Learn GDScript's custom Godot build

Learn GDScript uses a custom build of Godot 4.6.3 with some engine modifications that make the app possible. If you try to open the app in the official version of Godot, you will get some type errors as a result.

Download the editor for Linux from: https://github.com/Razoric480/custom-godot-builder/releases/tag/learn-4.6.3

## Building locally

If you need to export the app locally (e.g. to test the full build), use the `build.py` script:

```bash
# Downloads the custom Godot build and export templates, and prepares course scripts
python3 build.py prepare local

# Exports for a specific platform (the options are linux, windows, osx, web, or all)
python3 build.py export linux
```

To clean up downloaded files, run:

```bash
python3 build.py prepare clean
```

Note that this is only for doing local builds for testing, otherwise we use GitHub Actions to publish releases.
