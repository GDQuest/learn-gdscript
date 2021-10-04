# Represents an overlay pop-up, which appears when
# hovering a squiggly line.
# Edit properties and appearances in the accompanying Scene
extends MarginContainer

export var offset := Vector2(6.0, 6.0)

onready var _label: Label = $Label


func _ready() -> void:
	hide()


func display(message: String, position: Vector2) -> void:
	_label.text = message
	rect_global_position = position
	show()
