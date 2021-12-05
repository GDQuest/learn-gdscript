# Proxy for one GDScript file. Maintains a list of nodes using
# that script, as well as the different slices of that script.
#
# This resource implements the iterator pattern, so you can
# loop through internal ScriptHandlers with a simple
#
# ```
# for slice in script_handler:
# ```
#
# Use the `current()` method to get proper typing:
#
# ```
# for _ in script_handler:
#   var slice := script_handler.current()
# ```
class_name ScriptHandler
extends Resource

const EXPORT_ANNOTATION_REGEX = "(?m)^(?<leading_spaces>\\t*)#\\s(?<closing>\\/)?(?<keyword>EXPORT)(?: +(?<name>[\\w\\d]+))?"

# Array of nodes paths that are dependencies
#
# These are the nodes that get their script reloaded when this handler changes.
#
# See add_node_path() for more information.
export var nodes_paths: Array
# Path to the GDScript file
export var file_path := ""
# Basename of the GDScript file. Helps to display the name in the UI
export var name := ""
# Full text of the script
export var original_script := ""

# @type Dictionary[String,ScriptSlice]
export var slices := {}

# Regular expressions used to sanitize and split the srcripts
var _sanitization_replacements := RegExpGroup.collection(
	{
		"\\r\\n": "\\n",
	}
)
var _leading_spaces_regex := RegExpGroup.compile("(?m)^(?:  )+")
var _export_annotation_regex := RegExpGroup.compile(EXPORT_ANNOTATION_REGEX)

# Temporary values for iterations
var _current_index := 0
var _current_array := []


func _init() -> void:
	nodes_paths = []


# Each slice has a name decided based on a comment with the form `# EXPORT <name>`.
#
# Use * as the key to get the slice corresponding to the complete script.
func get_slice(key: String) -> ScriptSlice:
	return slices[key]


# Adds a node as a dependency of this script (a node that uses this script).
#
# This is usually used only at authoring time, but you may want to use this in
# case nodes using that script get created at runtime.
func add_node_path(path: NodePath) -> void:
	nodes_paths.append(path)


# Removes a node from the dependencies list. The removed node will not be
# updated when the script changes.
#
# Note nodes that don't exist anymore get skipped automatically, like freed
# nodes in the `nodes` array.
func remove_node_path(path: NodePath) -> void:
	var index := nodes_paths.find(path)
	if index > -1:
		nodes_paths.remove(index)


# Called by `SceneFiles` to assign a script to the handler.
#
# Sets up a few basic properties and slices the script string according to the
# EXPORT comments.
func set_initial_script(initial_script: GDScript) -> void:
	file_path = initial_script.resource_path
	name = file_path.get_file().get_basename()
	original_script = initial_script.source_code
	slices = _get_script_slices(original_script)


func current_key() -> String:
	var key = _current_array[_current_index]
	return key


func current() -> ScriptSlice:
	return get_slice(current_key())


# Splits a script in slices according to the EXPORT comments and returns them as
# a Dictionary[String, ScriptSlice].
func _get_script_slices(script: String) -> Dictionary:
	var sanitized_text := _sanitization_replacements.replace(script)
	var lines := sanitized_text.split("\n")
	var waiting_slices := {}
	var completed_slices := {}
	for index in lines.size():
		var line: String = lines[index]
		var spaces_match := _leading_spaces_regex.search(line)
		if spaces_match:
			var spaces: String = spaces_match.strings[0]
			var length = spaces.length()
			var replacement = "\\t".repeat(length / 2)
			line = replacement + line.substr(length)

		var export_match := _export_annotation_regex.search(line)
		if export_match:
			var slice = ScriptSlice.new()
			slice.from_regex_match(export_match)
			slice.start = index
			if slice.closing and slice.name:
				if slice.name in waiting_slices:
					var previous_slice: ScriptSlice = waiting_slices[slice.name]
					waiting_slices.erase(slice.name)
					previous_slice.end = index
					previous_slice.set_main_lines(lines)
					completed_slices[slice.name] = previous_slice
			elif slice.name:
				waiting_slices[slice.name] = slice
			elif slice.global:
				slice.set_main_lines(lines, true)
				slice.end = lines.size()
				completed_slices["*"] = slice
	return completed_slices


func _to_string():
	return "[%s, %s]" % [name, nodes_paths]


################################################################################
# Iterator pattern


func _iterator_is_valid() -> bool:
	return _current_index < _current_array.size()


func _iter_init(_arg) -> bool:
	_current_index = 0
	_current_array = slices.keys()
	return _iterator_is_valid()


func _iter_next(_arg) -> bool:
	_current_index += 1
	return _iterator_is_valid()


func _iter_get(_arg):
	return current_key()


################################################################################
# Array proxies


func size() -> int:
	return slices.size()
