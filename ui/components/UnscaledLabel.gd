@tool
class_name UnscaledLabel
extends Label


@export var forced_size := 20:
	set(value):
		forced_size = value
		_update_theme()


func _enter_tree() -> void:
	_update_theme()


func _update_theme() -> void:
	add_theme_font_size_override(&"font_size", forced_size)
