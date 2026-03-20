extends Control

# @type Array[Node]
@onready var _initial_crates := $Column.get_children()
# @type Array[int]
var crates := []

var _is_resetting := false


const code = """var crates = ["%s"]

func use_top_crate():
	var crate = crates.pop_back()
	use(crate)
"""


func _ready() -> void:
	_initial_crates.invert()
	var i:= 0
	for crate in _initial_crates:
		crate.set_label_index(i)
		i += 1
		crate.hide_after_animation = true
		crate.connect("restored", Callable(self, "restore_crate"))
	crates = range(_initial_crates.size())


func run() -> void:
	crates.pop_back()
	_sync_nodes()


func _sync_nodes():
	var index := crates.size()
	if index < 0:
		return
	var crate = _initial_crates[index]
	crate.use()
	var remaining = PackedStringArray()
	for crate_index in crates:
		remaining.append(_initial_crates[crate_index].get_texture_name())
	# TODO: display this to the user?
	prints(
		"removed: ", crate.get_texture_name(), 
		"remaining: ", '["'+'", "'.join(remaining)+'"]'
	)


func reset():
	restore_crate()


func restore_crate():
	var index = crates.size()
	if index >= _initial_crates.size():
		_is_resetting = false
	elif index < _initial_crates.size():
		crates.append(index)
		_initial_crates[index].reset()


func get_code(_initial_code: String) -> String:
	var names := PackedStringArray()
	for crate in _initial_crates:
		names.append(crate.get_texture_name())
	return code % ['", "'.join(names)]
