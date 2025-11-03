# Represents one slice of a script. This is typically a section of a script that
# corresponds to what you want the student to code in a practice.
class_name ScriptSlice
extends Resource

# Path to the .gd script file
export var script_path := ""
# Name of the EXPORT slice (e.g., "combo")
export var slice_name := ""
# Line numbers (0-indexed in source file, excluding EXPORT comment lines)
export var start := 0
export var end := 0
# Amount of leading spaces/tabs before the slice content
export var leading_spaces := 0
# Lines that are editable by the end user (the slice content)
export var lines_editable := []
# Lines before the editable region
export var lines_before := []
# Lines after the editable region
export var lines_after := []

# Cache for student's current code
var current_text := ""
# TODO: These properties come from the former builder addon/build step we had to
# pre-create slices as resources. I've replicated them to keep some of the old
# interface.
# Consider removing those and just keeping the functions to simplify the code.
var slice_text: String setget , get_slice_text
var start_offset: int setget , get_start_offset
var end_offset: int setget , get_end_offset


# Returns the path to the scene file (we derive this from script_path)
# TODO: in the future we should review this and consider if we can find
# something more reliable, or at least add a CI check/unit test to validate all
# paths
func get_scene_path() -> String:
	if script_path.empty():
		return ""
	var scene_path := script_path.get_basename() + ".tscn"
	return scene_path


# Loads and returns the scene for this practice
func get_scene() -> PackedScene:
	var scene_path := get_scene_path()
	if scene_path.empty() or not ResourceLoader.exists(scene_path):
		push_error("Scene not found: " + scene_path)
		return null
	return load(scene_path) as PackedScene


# Loads and returns the script source code
func get_script_source() -> String:
	if script_path.empty():
		return ""
	var file := File.new()
	if file.open(script_path, File.READ) != OK:
		push_error("Failed to read script: " + script_path)
		return ""
	var content := file.get_as_text()
	file.close()
	return content


# Returns just the filename for error reporting
func get_script_file_name() -> String:
	if script_path.empty():
		return ""
	return script_path.get_file()


# Returns the full script path
func get_script_file_path() -> String:
	return script_path


# Returns the base viewport size for this practice
# TODO: review the use of this, this was a plain constant. See if we couldn't
# allow users to change the resolution and also reduce the viewport of the
# embededded practice view (if it actually uses a separate viewport) for
# efficiency
func get_viewport_size() -> Vector2:
	return Vector2(1920, 1080)


# Returns the editable slice text
func get_slice_text() -> String:
	return PoolStringArray(lines_editable).join("\n")


# Returns the full script text with proper indentation
func get_full_text() -> String:
	var middle_text := _indent_lines(lines_editable, leading_spaces)
	return PoolStringArray(lines_before + middle_text + lines_after).join("\n")


# Returns all lines (before + editable + after) as an Array with proper indentation
# This is useful for tests that need to check the full script
func get_main_lines() -> Array:
	var middle_text := _indent_lines(lines_editable, leading_spaces)
	return lines_before + middle_text + lines_after


# Returns the full script text with student's code inserted
func get_current_full_text() -> String:
	var student_lines := current_text.split("\n")
	var middle_text := _indent_lines(student_lines, leading_spaces)
	return PoolStringArray(lines_before + middle_text + lines_after).join("\n")


# Returns the line offset where the editable region starts (for error positioning)
func get_start_offset() -> int:
	return lines_before.size()


# Returns the line offset where the editable region ends (for error positioning)
func get_end_offset() -> int:
	return lines_before.size() + lines_editable.size()


# Helper to indent lines by leading_spaces
func _indent_lines(lines: Array, indent_level: int) -> Array:
	if indent_level <= 0:
		return lines
	var indent := "\t".repeat(indent_level)
	var result := []
	for line in lines:
		result.append(indent + line)
	return result


# Takes the code of a slice and removes whitespace and commented lines.
# It makes it easier to check the student's source code via string match.
# Returns a string with the whitespace and comments erased.
static func preprocess_practice_code(code: String) -> String:
	var result := PoolStringArray()
	var comment_suffix := RegEx.new()
	comment_suffix.compile("#.*$")
	for line in code.split("\n"):
		line = line.strip_edges().replace(" ", "")
		if not (line.empty() or line.begins_with("#")):
			result.push_back(comment_suffix.sub(line, ""))
	return result.join("\n")
