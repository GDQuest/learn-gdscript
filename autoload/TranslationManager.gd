extends Node

signal translation_changed()

const I18N_ROOT := "res://i18n"
const PO_EXTENSION := "po"
# OS.get_locale() is available, if we want to guess the language based on the OS setting.
const DEFAULT_LOCALE := "en"
const SUPPORTED_LOCALES := [
	"en",
	"es",
]

var current_language := DEFAULT_LOCALE setget set_language

var _loaded_translations := []


func _ready() -> void:
	var current_profile := UserProfiles.get_profile()
	set_language(current_profile.language)


func get_available_languages() -> Array:
	var languages := []
	
	for locale_code in SUPPORTED_LOCALES:
		languages.append({
			"code": locale_code,
			"name": TranslationServer.get_locale_name(locale_code),
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
		
		_loaded_translations = []
	
	# If the language is set to the default locale, we don't need to do anything else.
	if current_language == DEFAULT_LOCALE:
		TranslationServer.set_locale(current_language)
		current_profile.language = current_language
		current_profile.save()
		emit_signal("translation_changed")
		return
	
	# Load order shouldn't be important, so we'll just load everything from the folder.
	var locale_dir_path := I18N_ROOT.plus_file(current_language)
	
	var fs := Directory.new()
	if not fs.dir_exists(locale_dir_path):
		printerr("Failed to change language to '%s': Language folder does not exist." % [ current_language ])
		_reset_language()
		return
	
	var error = fs.change_dir(locale_dir_path)
	if error:
		printerr("Failed to open language folder for '%s': Error code %d" % [ current_language, error ])
		_reset_language()
		return
	
	error = fs.list_dir_begin(true, true)
	if error:
		printerr("Failed to list language folder for '%s': Error code %d" % [ current_language, error ])
		_reset_language()
		return
	
	# Iterate through all PO files and try to load them.
	var file_path = fs.get_next()
	while file_path:
		if not file_path.get_extension() == PO_EXTENSION:
			file_path = fs.get_next()
			continue
		
		var full_path = locale_dir_path.plus_file(file_path)
		
		if not ResourceLoader.exists(full_path):
			printerr("Language file at '%s' is not recognized as a valid resource." % [ full_path ])
			file_path = fs.get_next()
			continue
		
		var translation := ResourceLoader.load(full_path, "Translation") as Translation
		if not translation:
			printerr("Language resource at '%s' has failed to load." % [ full_path ])
			file_path = fs.get_next()
			continue
		
		_loaded_translations.append(translation)
		file_path = fs.get_next()
	
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
