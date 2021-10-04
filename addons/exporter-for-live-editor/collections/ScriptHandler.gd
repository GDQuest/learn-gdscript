## Proxy for one GDScript file. Maintains a list of nodes using
## that script, as well as the different slices of that script.
## 
## 
## This resource implements the iterator pattern, so you can
## loop through internal ScriptHandlers with a simple
## ```
## for slice in script_handler:
##   ... do something with slice
## ```
##
## A `current()` method is supplied to get proper typing:
## ```
## for _ in script_handler:
##   var slice := script_handler.current()
## ```
extends Resource

const RegExp := preload("../utils/RegExp.gd")
const ScriptSlice := preload("./ScriptSlice.gd")
const EXPORT_ANNOTATION = "(?m)^(?<leading_spaces>\\t*)#\\s(?<closing>\\/)?(?<keyword>EXPORT)(?: +(?<name>[\\w\\d]+))?"

# Array of nodes paths that are dependencies
export var nodes: Array
# file path of the GDScript
export var file_path := ""
# basename of the file. This is a simple shortcut to display the name
# of the file in user interfaces
export var name := ""
# full text of the script
export var original_script := ""

# temporary values for iterations 
var _current_index := 0
var _current_array := []

# @type Dictionary<String,ScriptSlice>
export var slices := {}

# Regular expressions used to sanitize and split the srcripts
var sanitization_replacements := RegExp.collection(
	{
		"\\r\\n": "\\n",
	}
)
var leading_spaces_regex := RegExp.compile("(?m)^(?:  )+")
var export_annotation_regex := RegExp.compile(EXPORT_ANNOTATION)


func _init() -> void:
	nodes = []


# Each slice has a name, decided by the annotation
# `# EXPORT <name>` sets `<name>` as the slice name
# full slices have a key of `'*'`.
func get_slice(key: String) -> ScriptSlice:
	return slices[key]


# Adds a node as a dependency of this script (the node uses that script)
# these are the nodes that get their script reloaded when it changes
# This is usually used only at authoring time, but you may want to use this
# in case nodes using that script get created at runtime
func add_node(path: NodePath) -> void:
	nodes.append(path)


# Removes a node from the dependencies list. The removed node
# will not be updated when the script changes.
# There is in principle no reason to use this even if you have nodes that 
# get removed at runtime (i.e, ennemies that die and get `queue_free`d)
# because nodes that don't exist anymore get simply skipped.
func remove_node(path: NodePath) -> void:
	var index := nodes.find(path)
	if index > -1:
		nodes.remove(index)


# Called by `SceneFiles` to set the script. It sets up a few
# basic properties, and slices the script string according to the
# EXPORT annotations
func set_initial_script(initial_script: GDScript) -> void:
	file_path = initial_script.resource_path
	name = file_path.get_file().get_basename()
	original_script = initial_script.source_code
	slices = _get_script_slices(original_script)


# Splits a script in slices according to the EXPORT
# annotations, and returns the splits. This uses no context
# and could be a static function, but it requires the regexes, and
# GDScript doesn't allow static generated variables
# @returns Dictionary<String,ScriptSlice> 
func _get_script_slices(script: String) -> Dictionary:
	var sanitized_text := sanitization_replacements.replace(script)
	var lines := sanitized_text.split("\n")
	var waiting_slices := {}
	var completed_slices := {}
	for index in lines.size():
		var line: String = lines[index]
		var spacesMatch := leading_spaces_regex.search(line)
		if spacesMatch:
			var spaces: String = spacesMatch.strings[0]
			var length = spaces.length()
			var replacement = "\\t".repeat(length / 2)
			line = replacement + line.substr(length)
		var exportMatch := export_annotation_regex.search(line)
		if exportMatch:
			var slice = ScriptSlice.new()
			slice.from_regex_match(exportMatch)
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
	return "`%s`" % [file_path]


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


func current_key() -> String:
	var key = _current_array[_current_index]
	return key


func current() -> ScriptSlice:
	return get_slice(current_key())


################################################################################
# Array proxies


func size() -> int:
	return slices.size()
