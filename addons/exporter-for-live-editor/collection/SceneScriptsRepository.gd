extends Resource

const SceneScript := preload("./SceneScript.gd")

export var repository: Dictionary
var _scene: Node
var _current_index := 0
var _current_array := []


func _init(scene: Node) -> void:
	repository = {}
	_scene = scene


## If the provided script is new, adds a script file to the repository.
## Otherwise, adds the provided node as a dependency of this script.
func add_node(script: GDScript, node: Node) -> void:
	var script_path := script.resource_path
	if not (script_path in repository):
		prints("new script:", script_path)
		var scene_script := SceneScript.new(_scene, script)
		repository[script_path] = scene_script
	(repository[script_path] as SceneScript).append(node)


func _to_string():
	return '(scripts: %s)' % [PoolStringArray(repository.values()).join(", ")]


func _iterator_is_valid() -> bool:
	return _current_index < _current_array.size()


func _iter_init(_arg) -> bool:
	_current_index = 0
	_current_array = repository.values()
	return _iterator_is_valid()


func _iter_next(_arg) -> bool:
	_current_index += 1
	return _iterator_is_valid()


func _iter_get(_arg):
	return current()


func size() -> int:
	return repository.size()


func keys() -> Array:
	return repository.keys()


func values() -> Array:
	return repository.values()


func current() -> SceneScript:
	return _current_array[_current_index]
