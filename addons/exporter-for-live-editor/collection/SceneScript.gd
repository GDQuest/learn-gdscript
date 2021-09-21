## Manages one script. Maintains a list of nodes using that script, 
## and can replace their script.
extends Resource


signal errors(errors)


export var nodes: Array
export var file_path := ""
export var original_script := ""
export var name := ""
var _current_index := 0
var _scene: Node


func _init(scene:Node, initial_script: GDScript) -> void:
	nodes = []
	_scene = scene
	file_path = initial_script.resource_path
	name = file_path.get_file().get_basename()
	original_script = initial_script.source_code


func _to_string():
	return '`%s`' % [file_path]


func _iterator_is_valid() -> bool:
	return _current_index < nodes.size()


func _iter_init(_arg) -> bool:
	_current_index = 0
	return _iterator_is_valid()


func _iter_next(_arg) -> bool:
	_current_index += 1
	return _iterator_is_valid()


func _iter_get(_arg):
	return current()


func size() -> int:
	return nodes.size()

func get_by_index(index: int) -> NodePath:
	return nodes[index]

func current() -> NodePath:
	return get_by_index(_current_index)

func append(node: Node) -> void:
	var path := String(node.get_path()).replace(_scene.get_path(),"")
	prints("adding node %s to script %s"%[path, file_path])
	nodes.append(NodePath(path))
