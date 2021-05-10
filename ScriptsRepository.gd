# A dictionary of ScriptManagers

const ScriptManager = preload("./ScriptManager.gd")
var repository := {}

# if the provided script is new, adds a script file to the repository
# otherwise, adds the provided node as a dependency of this script
func add_script(script:GDScript, node: Node) -> void:
	var script_path := script.resource_path
	if not (script_path in repository):
		repository[script_path] = ScriptManager.new(script)
		
	repository[script_path].nodes.append(node)

func _to_string():
	return '(scripts: %s)'%[PoolStringArray(repository.values()).join(", ")]

var _current_index := 0
var _current_array := []

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
	return _current_array[_current_index]

func size() -> int:
	return repository.size()

func keys() -> Array:
	return repository.keys()

func values() -> Array:
	return repository.values()
