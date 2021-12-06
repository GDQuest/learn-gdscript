# Represents an overlay pop-up, which appears when
# hovering a squiggly line.
class_name ErrorOverlayPopup
extends MarginContainer

export var offset := Vector2(6.0, 6.0)

var error_message: String setget set_error_message

var _current_message_source: Node

onready var _error_label := $MarginContainer/Column/ErrorLabel as Label
onready var _error_explanation := $MarginContainer/Column/ErrorLabel as RichTextLabel


func _ready() -> void:
	hide()


func show_message(position: Vector2, message: String, message_source: Node) -> void:
	_current_message_source = message_source
	set_error_message(message)
	# TODO: The blob should likely be positioned next to the erring line based on the position argument.
	#rect_global_position = position
	show()


func hide_message(message_source: Node) -> void:
	if _current_message_source == message_source:
		hide()


func set_error_message(message: String) -> void:
	error_message = message
	if not is_inside_tree():
		yield(self, "ready")
	_error_label.text = message
