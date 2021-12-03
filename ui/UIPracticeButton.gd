extends Node

signal pressed

onready var _label := $Row/Label as Label
onready var _button := $Row/Button as Button


func setup(practice: Resource) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_label.text = practice.title
	_button.connect("pressed", Events, "emit_signal", ["practice_start_requested", practice])
