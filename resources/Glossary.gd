class_name Glossary
extends Resource

const GLOSSARY_FILE := "res://course/glossary.csv"

# This dictionary holds the glossary entries keyed by raw lowercase English
# keywords (both singular and plural). The keywords serve as the glossary
# entries' unique IDs we can look up regardless of the language. They're the
# same keys used in the bbcode in [glossary] tags.
var _glossary := {}


func _init() -> void:
	var file := FileAccess.open(GLOSSARY_FILE, FileAccess.READ)
	var _header := Array(file.get_csv_line())

	while not file.eof_reached():
		var csv_line := file.get_csv_line()
		if not csv_line[0]:
			break

		var raw_singular: String = csv_line[0].to_lower()
		var raw_plural: String = csv_line[1].to_lower()

		assert(not raw_singular in _glossary, "Duplicate key '%s' in glossary." % raw_singular)
		assert(raw_plural.is_empty() or not raw_plural in _glossary, "Duplicate key '%s' in glossary." % raw_plural)

		var entry := Entry.new(csv_line)
		_glossary[raw_singular] = entry
		if not raw_plural.is_empty():
			_glossary[raw_plural] = entry

	file.close()


# Call this function after a language change to rebuild translated display
# strings on all entries.
func reload() -> void:
	for entry: Entry in _glossary.values():
		entry.rebuild_translations()


func has(keyword: String) -> bool:
	return keyword.to_lower() in _glossary


func get_match(keyword: String) -> Entry:
	return _glossary.get(keyword.to_lower(), null)


class Entry:
	# The fields below store the source English keywords loaded from the
	# glossary data file.
	var raw_singular := ""
	var raw_plural := ""
	var raw_explanation := ""

	# These are the translated terms that get updated based on the selected
	# language in the user settings. They get populated once on initialization
	# and rebuilt on demand. The translations are then cached here.
	# (Nathan) I used properties mostly because we can't return simple tuples.
	var term := ""
	var plural_form := ""
	var explanation := ""


	func _init(csv_line: Array) -> void:
		raw_singular = csv_line[0] as String
		raw_plural = csv_line[1] as String
		raw_explanation = csv_line[2] as String
		rebuild_translations()


	func rebuild_translations() -> void:
		term = tr(raw_singular)
		plural_form = tr(raw_plural)
		explanation = TextUtils.tr_paragraph(raw_explanation)
