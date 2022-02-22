# Working with translations

The app offers internationalization support using PO (gettext) files. It's a popular format among translation professionals, and it has native support in Godot.

## How to contribute translations

When contributing translations, there are two cases:

1. **Translation files for your target language don't exist**. You need to create PO files from the template POT files in the correct directories and register the new language.
2. **Translation files for your target language already exist**. You need to open the corresponding PO files (not POT) and fill in the blanks.

### Adding a new language to the app

To add a new language to the app, you need to:

1. Create a new subdirectory of the `i18n/` directory with the two-letter code of your language. For example, `es/` for Spanish, `ru/` for Russian, or `zh/` for Chinese.
2. For each POT file in `i18n/`, create a derived PO translation file in your new subdirectory. You can use the program [Poedit](https://poedit.net/) to do so.
3. Open the TranslationManager.gd script and add your new language code to its `SUPPORTED_LOCALES` constant. The order of languages in `SUPPORTED_LOCALES` defines the order they'll appear in the settings menu.

The app may not support your language's characters. If that is the case, please [open an issue](https://github.com/GDQuest/learn-gdscript/issues) on the repository to add the missing font files and font switching code.

### Adding translations to PO files

To contribute translations, open the `i18n/` directory and open the subdirectory corresponding to your target language. For example, `i18n/es/` for Spanish.

There, you'll find PO translation files. To edit those, you'll need a dedicated program.

There are several free and open-source translation programs you can use to translate PO files. We recommend [Poedit](https://poedit.net/) as it's available on all three major desktop platforms and it offers an accessible interface.

Among other features, it allows you to mark translations you're unsure of as "needing work" so another translator can check it before publishing it.

### Testing your translations in Godot

You'll want to check your translations in Godot when translating the app.

First, you'll want to import the project in Godot.

Then, run the app by pressing <kbd>F5</kbd>, open the settings menu, and select the target language. The app will remember your choice when you reopen it.

Once you add many new translations, you can rerun the app to check their length doesn't cause overflowing or other UI issues. As words become longer or shorter in different languages, it's crucial to ensure the interface takes that into account.

If any bug appears in the interface with new translations, please [open a new issue](https://github.com/GDQuest/learn-gdscript/issues) and include a screenshot so we can fix it.

Finally, please note that if the app is running when you save translations, they may not reload in real-time. In that case, you'll need to close the app by pressing <kbd>F8</kbd> in Godot and rerun it by pressing <kbd>F5</kbd>.

## Translation files

We split translations for each language into many files. It helps translators to focus on a single lesson or aspect of the app at a time:

* `application.*` contains all translatable strings from the UI of the app. Note that this also includes placeholder text which we sometimes add to our reusable components.
* `classref_database.*` contains entries for the documentation section of the practice side panel, a class reference of sorts that explains some methods and properties to the student. It is based on `course/documentation.csv`.
* `error_database.*` contains explanations and suggestions for GDScript and internal errors. It is based on `lsp/error_database.csv`.
* `lesson-*.*` files contain all translatable strings from the course content. Currently, only content blocks, quizzes, and practices are translated. We currently don't support translatable content in scripts and scenes used by lessons.

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
