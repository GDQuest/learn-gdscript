extends Control

# In Godot 4, typed arrays provide better performance and autocompletion
@onready var _initial_crates: Array[Node] = $Column.get_children()

var index := 0
var _is_resetting := false


func _ready() -> void:
	# Godot 4: invert() is now reverse()
	_initial_crates.reverse()
	
	for i in range(_initial_crates.size()):
		var crate = _initial_crates[i]
		crate.set_label_index(i)
		
		# Godot 4 Signal syntax: signal.is_connected(callable)
		if not crate.used.is_connected(_pop_next):
			crate.used.connect(_pop_next)
		if not crate.restored.is_connected(_restore_next):
			crate.restored.connect(_restore_next)
	
	# Assigning the nodes to the crates variable (overwriting the strings for internal logic)
	crates = _initial_crates.duplicate()
	
	if get_tree().current_scene == self:
		_run()


func _run() -> void:
	run()
	index = _initial_crates.size() - 1
	_pop_next()
	

func _complete_run() -> void:
	# Godot 4: signal emission
	Events.practice_run_completed.emit()


func _pop_next() -> void:
	# Check if we have processed all items (crates is likely empty from the run() loop)
	if index < crates.size():
		_complete_run()
	else:
		var crate = _initial_crates[index]
		var crate_name = crate.get_texture_name()
		print("popping crate %d '%s'" % [index, crate_name])
		crate.use()
		index -= 1
	

func reset() -> void:
	crates = _initial_crates.duplicate()
	index = _initial_crates.size()
	_restore_next()
	

func _restore_next() -> void:
	index -= 1
	if index < 0:
		index = 0
		return
	_initial_crates[index].reset(3)


# EXPORT run
# Note: Initial values as strings for the student's perspective
var crates = [
	"healing heart",
	"shield",
	"gems",
	"sword"
]

func run() -> void:
	# is_empty() is the preferred way to check array size in Godot 4
	while not crates.is_empty():
		crates.pop_back()
# /EXPORT run
