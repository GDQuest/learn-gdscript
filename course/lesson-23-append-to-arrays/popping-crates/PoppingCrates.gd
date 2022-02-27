extends Control

onready var crates := $Column.get_children()

var use_index := 0


func _ready() -> void:
	crates.invert()
	var index := 0
	for crate in crates:
		crate.index = index
		index += 1
	use_index = 2


func _run():
	Events.emit_signal("practice_run_completed")


func reset():
	for crate in crates:
		crate.reset()


# EXPORT run
func run() -> void:
	if use_index < 0:
		return
	crates[use_index].use()
	use_index -= 1
# /EXPORT run
