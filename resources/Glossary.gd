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
	_glossary = _parse_glossary_file(glossary_file)
	var patterns := PoolStringArray()
	for key in _glossary:
		patterns.append(key)
	var terms_pattern := "(%s)" % patterns.join("|")
	print(terms_pattern)
	_glossary_regex.compile(terms_pattern)


func replace_matching_terms(text_bbcode: String) -> String:
	return _glossary_regex.sub(text_bbcode, "[url=$1]$1[/url]", true)


func has(keyword: String) -> bool:
	return keyword in _glossary


func get_match(keyword: String) -> Entry:
	return _glossary[keyword.to_lower()]


# Parses the input CSV file and returns a dictionary mapping keywords to
# glossary entries.
static func _parse_glossary_file(path: String) -> Dictionary:
	var glossary := {}
	var file := File.new()
	file.open(path, file.READ)
	var _header := Array(file.get_csv_line())

	while !file.eof_reached():
		var csv_line := file.get_csv_line()
		if not csv_line[0]:
			break

		var keyword = csv_line[0]
		assert(not keyword in glossary, "Duplicate key %s in glossary." % keyword)
		var entry := Entry.new(csv_line)
		glossary[keyword] = entry
		var plural_form = csv_line[1]
		if plural_form:
			glossary[plural_form] = entry

	file.close()
	return glossary


class Entry:
	var term: String
	var plural_form: String
	var explanation: String

	func _init(csv_line: Array) -> void:
		term = csv_line[0].capitalize()
		plural_form = csv_line[1]
		explanation = csv_line[2]
