# Represents a slice from the script file.
tool
extends Resource
class_name SliceProperties

const SceneProperties = preload("./SceneProperties.gd")
const ScriptProperties = preload("./ScriptProperties.gd")

export var scene_properties: Resource setget set_scene_properties, get_scene_properties
export var script_properties: Resource setget set_script_properties, get_script_properties
# Amount of tabs before a slice annotation. We normalize scripts to use tabs for indentation.
export var leading_spaces := 0
# Annotation keyword. It's always `EXPORT` for the moment, but if more keywords
# are added later, this could change
export var keyword := "EXPORT"
# True if the slice is a closing slice.
#
# Closing slices are only used to determine slice limits during slicing, and
# thrown away later. You shouldn't ever see this being true
export var closing := false
# Name of the slice. Will be empty if is_full_file is true
export var name := ""
# True if the slice corresponds to a full script
export var is_full_file := false
# Start line of the slice, excluding the keyword comment
export var start := 0
# End of the slice, excluding the keyword comment
export var end := 0
# All the lines before the slice
export var lines_before := []
# All the lines after the slice
export var lines_after := []
# All the lines of the slice
export var lines_editable := []

# Returns the slice
var slice_text: String setget _read_only, get_slice_text
# Returns the recomposed file
var full_text: String setget _read_only, get_full_text
# A cache for the modified slice
var current_text: String
# Returns the full text, but the slice is replaced with the modified slice
var current_full_text: String setget _read_only, get_current_full_text
# Returns the amount of lines before the slice
var start_offset: int setget _read_only, get_start_offset
# Returns the amount of lines before the slice, plus the amount of lines in the
# slice
var end_offset: int setget _read_only, get_end_offset


func _init() -> void:
	lines_before = []
	lines_after = []
	lines_editable = []


# Indents every line of a text by `indent_amount`
static func _indent_text(indent_amount: int, lines: PoolStringArray) -> PoolStringArray:
	var _text = PoolStringArray()
	var indent = "\t".repeat(indent_amount)
	for index in lines.size():
		var line: String = lines[index]
		_text.append(indent + line)
	return _text


# Sets the slice's properties from a regex match. The regex needs to have the
# specific named groups used in the function
func from_regex_match(result: RegExMatch) -> void:
	#prints("result:", result, "|" + result.get_string("leading_spaces") + "|", result.get_string("leading_spaces").length(), result.names)
	leading_spaces = result.get_string("leading_spaces").length()
	keyword = result.get_string("keyword")
	closing = result.get_string("closing") != ""
	name = result.get_string("name")
	is_full_file = name == ""
	#prints("leading spaces", leading_spaces)


# Splits lines in three parts: before, after, and editable. requires `start` and
# `end` properties to be set beforehand.
func set_main_lines(lines: Array, is_is_full_file := false) -> void:
	lines_before = lines.slice(0, start - 1) if not is_is_full_file else []
	lines_after = lines.slice(end + 1, lines.size()) if not is_is_full_file else []
	lines_editable = lines.slice(start + 1, end - 1)
	if leading_spaces:
		for index in lines_editable.size():
			var line: String = lines_editable[index]
			line = line.substr(leading_spaces)
			lines_editable[index] = line


# Returns all the lines as an Array[String], including the middle slice, with
# proper indentation
func get_main_lines() -> Array:
	var middle_text := (
		Array(_indent_text(leading_spaces, lines_editable))
		if leading_spaces
		else lines_editable
	)
	return lines_before + middle_text + lines_after


# Returns the slice itself
func get_slice_text() -> String:
	return PoolStringArray(lines_editable).join("\n")


# Returns the full text, with proper indentation
func get_full_text() -> String:
	return PoolStringArray(get_main_lines()).join("\n")


# Returns the full text, with proper indentation, with the current text
# (temporary text buffer) instead of the slice
func get_current_full_text() -> String:
	var lines = current_text.split("\n")
	var middle_text := Array(_indent_text(leading_spaces, lines) if leading_spaces else lines)
	return PoolStringArray(lines_before + middle_text + lines_after).join("\n")


func get_start_offset() -> int:
	return lines_before.size()


func get_end_offset() -> int:
	return lines_before.size() + lines_editable.size()


func set_scene_properties(new_scene_resource: Resource) -> void:
	if new_scene_resource is SceneProperties:
		scene_properties = new_scene_resource
	assert(new_scene_resource is SceneProperties)


func get_scene_properties() -> SceneProperties:
	return scene_properties as SceneProperties


func set_script_properties(new_script_resource: Resource) -> void:
	if new_script_resource is ScriptProperties:
		script_properties = new_script_resource
	assert(new_script_resource is ScriptProperties)


func get_script_properties() -> ScriptProperties:
	return script_properties as ScriptProperties


func get_save_name() -> String:
	if script_properties:
		var extension := ('.' + name if name != '*' else 'ALL') + '.slice'
		var file_name := get_script_properties().file_name + extension
		return file_name
	return ''


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
	#return JSON.print(as_json(), "  ")
	return "(%s:%s)" % [script_properties.get_save_name(), name]


func _read_only(new_text) -> void:
	push_error("Don't try to set this value")
	return
