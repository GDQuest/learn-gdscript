extends Control

# @type Array[Node]
onready var _initial_crates := $Column.get_children()
# @type Array[int]
var crates := []

var _is_resetting := false


func _ready() -> void:
	_initial_crates.invert()
	for crate in _initial_crates:
		crate.connect("restored", self, "restore_crate")
	crates = range(_initial_crates.size())


func run() -> void:
	crates.pop_back()
	_sync_nodes()


func _sync_nodes():
	var index := crates.size()
	if index < 0:
		return
	_initial_crates[index].use()


func reset():
	restore_crate()


func restore_crate():
	var index = crates.size()
	if index >= _initial_crates.size():
		_is_resetting = false
	elif index < _initial_crates.size():
		crates.append(index)
		_initial_crates[index].reset()
