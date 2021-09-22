extends Resource

const ScriptHandler := preload("./ScriptHandler.gd")

export var files: Dictionary
var _scene: Node
var _current_index := 0
var _current_array := []


func _init(scene: Node) -> void:
	files = {}
	_scene = scene


## If the provided script is new, adds a script file to the files.
## Otherwise, adds the provided node as a dependency of this script.
func add_node(script: GDScript, node: Node) -> void:
	var script_path := script.resource_path
	if not (script_path in files):
		var scene_script := ScriptHandler.new(_scene, script)
		files[script_path] = scene_script
	var path := NodePath(String(node.get_path()).replace(_scene.get_path(), ""))
	(files[script_path] as ScriptHandler).append(path)


func _to_string():
	return '(scripts: %s)' % [PoolStringArray(files.values()).join(", ")]


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


func size() -> int:
	return files.size()


func keys() -> Array:
	return files.keys()


func values() -> Array:
	return files.values()


func current() -> ScriptHandler:
	return _current_array[_current_index]
