class_name Glossary
extends Resource

var glossary_file := "res://course/glossary.csv"

# Multiple keywords could point to the same definition, so we could use shared objects and map multiple keys to them.
# Examples: call function and function call.
# Dictionary mapping keywords or expressions to a definition.
var _glossary := {}
# Single regex to find all matching keywords in rich text labels. Used to detect
# and wrap glossary entries in rich text labels.
var _glossary_regex := RegEx.new()

func _init() -> void:
	setup()

func setup() -> void:
	_glossary = _parse_glossary_file(glossary_file)
	var patterns := PackedStringArray()
	for key in _glossary:
		patterns.append(key)
	var terms_pattern := "(?:\\[ignore\\]\\w+)(*SKIP)(*F)|(%s)" % "|".join(patterns)

	_glossary_regex.compile(terms_pattern)


func replace_matching_terms(text_bbcode: String) -> String:
	return _glossary_regex.sub(text_bbcode, "[url=$1]$1[/url]", true).replace("[ignore]", "")


func has(keyword: String) -> bool:
	return keyword in _glossary


func get_match(keyword: String) -> Entry:
	var key := keyword.to_lower()
	if not key in _glossary:
		return null
	return _glossary[keyword.to_lower()]


# Parses the input CSV file and returns a dictionary mapping keywords to
# glossary entries.
func _parse_glossary_file(path: String) -> Dictionary:
	var glossary := {}
	var file := FileAccess.open(path, FileAccess.READ)
	var _header := Array(file.get_csv_line())

	while !file.eof_reached():
		var csv_line := file.get_csv_line()
		if not csv_line[0]:
			break

		var plural_form = tr(csv_line[1])
		var keyword = tr(csv_line[0])
		assert(not keyword in glossary, "Duplicate key %s in glossary." % keyword)
		assert(not plural_form in glossary, "Duplicate key %s in glossary." % keyword)
		var entry := Entry.new(csv_line)
		if plural_form:
			glossary[plural_form] = entry
		glossary[keyword] = entry

	file.close()
	return glossary


class Entry:
	var term: String
	var plural_form: String
	var explanation: String

	func _init(csv_line: Array) -> void:
		term = tr(csv_line[0]).capitalize()
		plural_form = tr(csv_line[1])
		explanation = TextUtils.tr_paragraph(csv_line[2])
