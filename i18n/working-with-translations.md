# Working with translations

We are using PO files to drive our internationalization system. This is a format that is widely accepted by translation professionals, and it has native support in Godot. As such, normal Godot practices apply when adding translation support to the UI. Native components are automatically translated by the engine, while programmatically added string literals need to be wrapped in `tr(...)`.

Translations are loaded dynamically, instead of being preloaded using project settings. This is required because we separate localization resources into several files per each supported language. This applies to both PO templates (POT files), and translated PO files.

* `application.*` contains all translatable strings from the UI of the app. Note that this also includes placeholder text which we sometimes add to our reusable components.
* `classref_database.*` contains entries for the documentation section of the practice side panel, a class reference of sorts that explains some methods and properties to the student. It is based on `course/documentation.csv`.
* `error_database.*` contains error explanations and suggestions for GDScript and internal errors. It is based on `lsp/error_database.csv`.
* `lesson-*.*` files contain all translatable strings from the course content. Currently, only content blocks, quizzes, and practices are translated. If there is some translatable content in scripts and scenes used by lessons, it is currently ignored.

### Updating translation templates

To update POT files you need to have `babel` and `babel-godot` installed for Python, following [recommendations](https://docs.godotengine.org/en/stable/tutorials/i18n/localization_using_gettext.html#creating-the-po-template-pot-using-pybabel) from the official Godot documentation.

Extraction is described by a script located next to this instruction. You can call it from the root of the project like so:

```
python ./i18n/extract.py
```

### Updating translations

Each supported language is contained in a subdirectory of `./i18n`. All PO files must be named the same as their corresponding templates. This is not strictly required by the internationalization system of the project, but it helps with maintenances. On the same note, subdirectories can contain other PO files as well, and they will be loaded. Be aware of that.

Directory name is based on the language code. Create it if its missing, then simply drop the translated files into the directory.

In code, `TranslationManager` autoloaded singleton is responsible for loading translations. If you add a new language, don't forget to update its `SUPPORTED_LOCALES` constant. The order defines the order in the settings menu, so pay close mind to it.

Note, that resources in Godot are cached, so if you are running the app already and the resources has been previously loaded, hot-reloading will be unlikely. Restart the app to see the changes (but not the editor, that's fine).
