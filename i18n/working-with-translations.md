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
