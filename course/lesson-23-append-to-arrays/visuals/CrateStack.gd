extends Control

# In Godot 4, we use typed arrays for better performance and editor support
@onready var _initial_crates: Array[Node] = $Column.get_children()
var crates: Array[int] = []

var _is_resetting := false

const code = """var crates = ["%s"]

func use_top_crate():
	var crate = crates.pop_back()
	use(crate)
"""


func _ready() -> void:
	# Godot 4: Array.invert() is now Array.reverse()
	_initial_crates.reverse()
	
	for i in range(_initial_crates.size()):
		var crate = _initial_crates[i]
		# Assuming Crate nodes have these methods/properties
		crate.set_label_index(i)
		crate.hide_after_animation = true
		# Godot 4 Signal connection syntax
		crate.restored.connect(restore_crate)
	
	# Assign range to typed array
	crates.clear()
	for i in range(_initial_crates.size()):
		crates.append(i)


func run() -> void:
	if not crates.is_empty():
		crates.pop_back()
		_sync_nodes()


func _sync_nodes() -> void:
	var index := crates.size()
	if index < 0 or index >= _initial_crates.size():
		return
		
	var crate = _initial_crates[index]
	if crate.has_method("use"):
		crate.use()
	
	var remaining := PackedStringArray()
	for crate_index in crates:
		remaining.append(_initial_crates[crate_index].get_texture_name())
	
	# CHANGED HERE:
	prints(
		"removed: ", crate.get_texture_name(), 
		"remaining: ", '["' + '", "'.join(remaining) + '"]'
	)



func reset() -> void:
	restore_crate()


func restore_crate() -> void:
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
	
	# CHANGED HERE:
	return code % ['", "'.join(names)]
