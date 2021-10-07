# Holds a list of ScriptHandlers for one scene.
# Each ScriptHandler corresponds to one GDScript file.
#
# This resource implements the iterator pattern, so you can
# loop through internal ScriptHandlers with a simple
#
# ```
# for script_handler in scene_files:
# ```
#
# Use the `current()` method to get proper typing:
#
# ```
# for _ in scene_files:
#   var script_handler := scene_files.current()
# ```
extends Resource

const ScriptHandler := preload("./ScriptHandler.gd")
const RegExp := preload("../utils/RegExp.gd")

# Holds references to ScriptHandlers
export var files: Dictionary
# Specific scene this collection of files pertains to
export var scene: PackedScene
export var scene_viewport_size: Vector2

var _current_index := 0
var _current_array := []


# If we don't re-initialize internal dicts and arrays, they're shared by all
# resources
func _init() -> void:
	files = {}


func collect_scripts(packed_scene: PackedScene, unpacked_scene: Node, limit := 1000):
	scene = packed_scene
	scene_viewport_size = Vector2(
		float(ProjectSettings.get_setting("display/window/size/width")),
		float(ProjectSettings.get_setting("display/window/size/height"))
	)
	_collect_scripts(unpacked_scene, unpacked_scene, self, limit)


# If the provided script is new, adds a script file to the files. Otherwise,
# adds the provided node as a dependency of this script.
func add_node(root_scene: Node, script: GDScript, node: Node) -> void:
	var script_path := script.resource_path
	var script_handler: ScriptHandler
	if not (script_path in files):
		script_handler = ScriptHandler.new()
		script_handler.set_initial_script(script)
		files[script_path] = script_handler
	else:
		script_handler = files[script_path] as ScriptHandler
	var path := get_node_relative_path(root_scene, node)
	script_handler.add_node_path(path)


static func get_node_relative_path(root_scene: Node, node: Node) -> NodePath:
	var root_path := String(root_scene.get_path()) + "/"
	var path := NodePath(String(node.get_path()).replace(root_path, ""))
	return path


func get_file(file_name: String) -> ScriptHandler:
	return files[file_name]


func _to_string():
	return "(scripts: %s)" % [PoolStringArray(files.values()).join(", ")]


################################################################################
# Iterator pattern


func _iterator_is_valid() -> bool:
	return _current_index < _current_array.size()


func _iter_init(_arg) -> bool:
	_current_index = 0
	_current_array = files.values()
	return _iterator_is_valid()


func _iter_next(_arg) -> bool:
	_current_index += 1
	return _iterator_is_valid()


func _iter_get(_arg):
	return current()


func current() -> ScriptHandler:
	return _current_array[_current_index]


################################################################################
# Dict proxies


func size() -> int:
	return files.size()


func keys() -> Array:
	return files.keys()


func values() -> Array:
	return files.values()


################################################################################
# Static helpers

static func script_has_annotation(script: GDScript) -> bool:
	var export_key_regex := RegExp.compile(ScriptHandler.EXPORT_ANNOTATION_REGEX)
	var result = export_key_regex.search(script.source_code)
	if result != null:
		return true
	return false

static func _collect_scripts(scene: Node, node: Node, repository, limit: int):
	var maybe_script: Reference = node.get_script()
	if maybe_script != null and maybe_script is GDScript:
		var script: GDScript = maybe_script
		if script_has_annotation(script):
			print("hello?")
			repository.add_node(scene, script, node)
	if limit > 0:
		limit -= 1
		for child in node.get_children():
			_collect_scripts(scene, child, repository, limit)
