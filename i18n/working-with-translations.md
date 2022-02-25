# Working with translations

The app offers internationalization support using PO (gettext) files.

It's a popular format among translation professionals, and it has native support in Godot.

We keep the translation files in a separate repository. To contribute translations, please head to the [learn-gdscript-translations](https://github.com/GDQuest/learn-gdscript-translations) repository, where you'll find detailed instructions.

## How translations work in Godot and the app

The engine automatically translates UI nodes, while we need to wrap string literals in calls to the `tr()` function.

In your typical Godot project, you would preload translation resources through the project settings.

Instead, this app loads translations dynamically because we separate localization resources into several files per supported language. This applies to both POT files (translation templates) and translated PO files.

### Updating translation templates

The gettext translation format comes with two file extensions: POT for translation templates and PO for translations to a specific language.

PO files derive from POT files, which allow us to track strings that changed between releases finely.

To update POT files, you need to have `babel` and `babel-godot` installed for Python, following [recommendations](https://docs.godotengine.org/en/stable/tutorials/i18n/localization_using_gettext.html#creating-the-po-template-pot-using-pybabel) from the official Godot documentation.

We use a python script to extract docstrings. You can call it from the root of the project like so:

```
python ./i18n/extract.py
```

You then need to copy the POT files over to the [learn-gdscript-translations](https://github.com/GDQuest/learn-gdscript-translations) repository where we translate the content.

### Adding a new language to the app

To add a new language to the app, you need to:

1. Create a new subdirectory of the `i18n/` directory with the two-letter code of your language. For example, `es/` for Spanish, `ru/` for Russian, or `zh/` for Chinese.
2. For each POT file in `i18n/`, create a derived PO translation file in your new subdirectory. You can use the program [Poedit](https://poedit.net/) to do so.
3. Open the TranslationManager.gd script and add your new language code to its `SUPPORTED_LOCALES` constant. The order of languages in `SUPPORTED_LOCALES` defines the order they'll appear in the settings menu.

The app may not support your language's characters. If that is the case, please [open an issue](https://github.com/GDQuest/learn-gdscript/issues) on the repository to add the missing font files and font switching code.
