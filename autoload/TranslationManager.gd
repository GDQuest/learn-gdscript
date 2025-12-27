extends Node

signal translation_changed()

const I18N_ROOT := "res://i18n"
const PO_EXTENSION := "po"
# OS.get_locale() is available, if we want to guess the language based on the OS setting.
const DEFAULT_LOCALE := "en"
const SUPPORTED_LOCALES: PackedStringArray = [
	"en",
	"fr",
	"es",
	"ja",
	"it",
	"pt_BR",
	"zh_Hans",
	"ru",
	"de",
	"tr",
	"nl",
	"uk",
	"zh_Hant",
	"cs",
	"bg",
]

const LOCALE_TO_LABEL := {
	"fr": "Français",
	"es": "Español",
	"ja": "日本語",
	"it": "Italiano",
	"pt_BR": "Portugés",
	"zh_Hans": "中文",
	"ru": "русский",
	"de": "Deutsch",
	"tr": "Türkçe",
	"nl": "Nederlands",
	"uk": "Українська",
	"zh_Hant": "繁體中文",
	"cs": "Čeština",
	"bg": "Български",
}

var current_language: String = DEFAULT_LOCALE:
	set(value):
		set_language(value)
		
var _loaded_translations: Array[Translation] = []


func _ready() -> void:
	var current_profile := UserProfiles.get_profile()
	set_language(current_profile.language)


func get_available_languages() -> Array[Dictionary]:
	var languages: Array[Dictionary] = []

	for locale_code in SUPPORTED_LOCALES:
		var language_name: String = LOCALE_TO_LABEL.get(locale_code, "") as String
		if language_name == "":
			language_name = TranslationServer.get_locale_name(locale_code)

		languages.append({
			"code": locale_code,
			"name": language_name,
		})

	return languages


func set_language(language_code: String) -> void:
	if current_language == language_code:
		return

	current_language = language_code
	var current_profile := UserProfiles.get_profile()

	# Remove existing translations from the translation server.
	if _loaded_translations.size() > 0:
		for translation in _loaded_translations:
			TranslationServer.remove_translation(translation)
		_loaded_translations.clear()

	# If the language is set to the default locale, we don't need to do anything else.
	if current_language == DEFAULT_LOCALE:
		TranslationServer.set_locale(current_language)
		current_profile.language = current_language
		current_profile.save()
		emit_signal("translation_changed")
		return

	# Load order shouldn't be important, so we'll just load everything from the folder.
	var locale_dir_path := I18N_ROOT.path_join(current_language)

	# Check folder exists first.
	if not DirAccess.dir_exists_absolute(locale_dir_path):
		printerr("Failed to change language to '%s': Language folder does not exist." % [current_language])
		_reset_language()
		return

	var fs := DirAccess.open(locale_dir_path)
	if fs == null:
		printerr("Failed to open language folder for '%s'." % [current_language])
		_reset_language()
		return

	fs.list_dir_begin()
	var file_name := fs.get_next()
	while file_name != "":
		if file_name.get_extension() != PO_EXTENSION:
			file_name = fs.get_next()
			continue

		var full_path := locale_dir_path.path_join(file_name)

		if not ResourceLoader.exists(full_path):
			printerr("Language file at '%s' is not recognized as a valid resource." % [full_path])
			file_name = fs.get_next()
			continue

		var translation := ResourceLoader.load(full_path) as Translation
		if not translation:
			printerr("Language resource at '%s' has failed to load." % [full_path])
			file_name = fs.get_next()
			continue

		_loaded_translations.append(translation)
		file_name = fs.get_next()

	# Add loaded translations to the translation server.
	for translation in _loaded_translations:
		TranslationServer.add_translation(translation)

	# Set the language to update the app.
	TranslationServer.set_locale(current_language)
	current_profile.language = current_language
	current_profile.save()
	emit_signal("translation_changed")

func _reset_language() -> void:
	current_language = DEFAULT_LOCALE
	TranslationServer.set_locale(current_language)

	var current_profile := UserProfiles.get_profile()
	current_profile.language = current_language
	current_profile.save()
