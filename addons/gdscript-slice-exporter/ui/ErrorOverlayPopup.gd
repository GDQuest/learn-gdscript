# Represents an overlay pop-up, which appears when
# hovering a squiggly line.
class_name ErrorOverlayPopup
extends MarginContainer

export var offset := Vector2(6.0, 6.0)

var error_message: String setget set_error_message

onready var _error_label := $MarginContainer/Column/ErrorLabel as Label
onready var _error_explanation := $MarginContainer/Column/ErrorLabel as RichTextLabel


func _ready() -> void:
	hide()


func display(message: String, position: Vector2) -> void:
	set_error_message(message)
	rect_global_position = position
	show()


func set_error_message(message: String) -> void:
	error_message = message
	if not is_inside_tree():
		yield(self, "ready")
	_error_label.text = message
