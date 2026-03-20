extends Control

# @type Array[Node]
@onready var _initial_crates := $Column.get_children()

var _crates := []
var index := 0
var _is_resetting := false


func _ready() -> void:
	_initial_crates.invert()
	var i:= 0
	for crate in _initial_crates:
		crate.set_label_index(i)
		i += 1
		if not crate.is_connected("used", Callable(self, "_pop_next")):
			crate.connect("used", Callable(self, "_pop_next"))
		if not crate.is_connected("restored", Callable(self, "_restore_next")):
			crate.connect("restored", Callable(self, "_restore_next"))
	crates = _initial_crates.duplicate()
	if get_tree().current_scene == self:
		_run()


func _run() -> void:
	run()
	index = _initial_crates.size() -1
	_pop_next()
	

func _complete_run() -> void:
	Events.emit_signal("practice_run_completed")

func _pop_next():
	if index < crates.size():
		_complete_run()
	else:
		var crate = _initial_crates[index]
		var crate_name = crate.get_texture_name()
		print("popping crate %s '%s'"%[index, crate_name])
		crate.use()
		index -= 1
	

func reset():
	crates = _initial_crates.duplicate()
	index =  _initial_crates.size()
	_restore_next()
	
func _restore_next():
	index -= 1
	if index < 0:
		index = 0;
		return
	_initial_crates[index].reset(3)

# EXPORT run
var crates = [
	"healing heart",
	"shield",
	"gems",
	"sword"
]

func run():
	while crates:
		crates.pop_back()
# /EXPORT run
