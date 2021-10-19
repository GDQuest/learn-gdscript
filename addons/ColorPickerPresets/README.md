# Godot ColorPicker Presets

Reads a color presets hex file in the addon local directory, called `presets.hex`. It adds the colors to the editor ColorPicker for quick access.

This repository includes a `presets.hex` file as an example. It's the [Pear36 color palette](https://lospec.com/palette-list/pear36) and you can directly download it from lospec.

![lospec download](./readme/lospec-download.png)

Follow the format of placing one hex color value per line:

```
5e315b
8c3f5d
ba6156
etc.
```

## ✗ WARNING

The addon:

1. Doesn't check the length of the color palette/file.
1. Skips malformed text lines without warning. It uses the ones it can convert to `Color`.
1. Overwrites the _ColorPicker_ presets whenever you reopen the project or re-enable the addon.

## ✓ Install

1. Make a new folder at `res://addons/ColorPickerPresets/`.
1. Copy the contents of this repository into `res://addons/ColorPickerPresets/`.
1. Replace `res://addons/ColorPickerPresets/presets.hex` with your prefered version.
1. Enable the addon from `Project > Project Settings... > Plugins`.
1. Profit.

![install project settings](./readme/install-project-settings.png)

## Where do I find the presets?

They'll be available in the editor _ColorPicker_.

![ColorPicker presets](./readme/colorpicker-presets.png)
