## Represents a slice from the script file.
extends Resource
const RegExp := preload("../utils/RegExp.gd")

# Amount of tabs before a slice annotation. It's always tabs because
# scripts are standardized before slicing them
export var leading_spaces := 0

# Annotation keyword. It's always `EXPORT` for the moment, but
# if more keywords are added later, this could change
export var keyword := "EXPORT"

# If the slice is a closing slice, this will be true. Closing slices
# are only used to determine slice limits during slicing, and thrown
# away later. You shouldn't ever see this being true 
export var closing := false

# Name of the slice. Will be empty if is_full_file is true
export var name := ""

# True if the slice is a full file slice
export var is_full_file := false

# Start of the slice, excluding keyword (unless it's a full file 
# slice, in which case it's 0)
export var start := 0

# End of the slice, excluding keyword (if it's a full file slice,
# it represents the last line of the file)
export var end := 0

# Contains all the lines before the slice
export var lines_before := []

# Contains all the lines after the slice
export var lines_after := []

# Contains the lines of the slice
export var lines_editable := []

# Returns the slice
var slice_text: String setget _read_only, get_slice_text

# Returns the recomposed file
var full_text: String setget _read_only, get_full_text

# A cache for the modified slice
var current_text: String setget set_current_text, get_current_text

# Returns the full text, but the slice is replaced with the modified
# slice
var current_full_text: String setget _read_only, get_current_full_text

# Returns the amount of lines before the slice
var start_offset: int setget _read_only, get_start_offset

# Returns the amount of lines before the slice, plus the 
# amount of lines in the slice
var end_offset: int setget _read_only, get_end_offset


func _init() -> void:
	lines_before = []
	lines_after = []
	lines_editable = []


# indents every line of a text by `indent_amount`
static func indent_text(indent_amount: int, lines: PoolStringArray) -> PoolStringArray:
	var _text = PoolStringArray()
	var indent = "\t".repeat(indent_amount)
	for idx in lines.size():
		var line: String = lines[idx]
		_text.append(indent + line)
	return _text


# Sets the slice's properties from a regex match. The regex
# needs to have the specific named groups used in the function
func from_regex_match(result: RegExMatch):
	leading_spaces = result.get_string("leading_spaces").length()
	keyword = result.get_string("keyword")
	closing = result.get_string("closing") != ""
	name = result.get_string("name")
	is_full_file = name == ""


# Splits lines in three parts, before, after, and editable.
# requires `start` and `end` properties to be set beforehand
func set_main_lines(lines: Array, is_is_full_file := false) -> void:
	lines_before = lines.slice(0, start - 1) if not is_is_full_file else []
	lines_after = lines.slice(end + 1, lines.size()) if not is_is_full_file else []
	lines_editable = lines.slice(start + 1, end - 1)
	if leading_spaces:
		for idx in lines_editable.size():
			var line: String = lines_editable[idx]
			line = line.substr(leading_spaces)
			lines_editable[idx] = line


# Returns all the lines, including the middle slice, with proper
# indentation
# @return Array<String> 
func get_main_lines() -> Array:
	var middle_text := (
		Array(indent_text(leading_spaces, lines_editable))
		if leading_spaces
		else lines_editable
	)
	return lines_before + middle_text + lines_after


# Trap for disallowed setters
func _read_only(new_text) -> void:
	push_error("Don't try to set this value")
	return


# Returns the slice itself
func get_slice_text() -> String:
	return PoolStringArray(lines_editable).join("\n")


# Returns the full text, with proper indentation
func get_full_text() -> String:
	return PoolStringArray(get_main_lines()).join("\n")


# Returns the full text, with proper indentation, with the
# current text (temporary text buffer) instead of the slice
func get_current_full_text() -> String:
	if current_text == "":
		return get_full_text()
	var lines = current_text.split("\n")
	var middle_text := Array(indent_text(leading_spaces, lines) if leading_spaces else lines)
	return PoolStringArray(lines_before + middle_text + lines_after).join("\n")


func set_current_text(new_current_text: String) -> void:
	current_text = new_current_text


func get_current_text() -> String:
	if current_text == "":
		return get_slice_text()
	return current_text


func get_start_offset() -> int:
	return lines_before.size()


func get_end_offset() -> int:
	return lines_before.size() + lines_editable.size()


func as_json() -> Dictionary:
	return {
		"leading_spaces": leading_spaces,
		"keyword": keyword,
		"closing": closing,
		"name": name,
		"is_full_file": is_full_file,
		"start": start,
		"end": end,
		"lines_editable": lines_editable,
		"lines_before": lines_before,
		"lines_after": lines_after
	}


func _to_string() -> String:
	return JSON.print(as_json(), "\t")
