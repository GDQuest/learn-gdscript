class_name UnscaledLabel
extends Label


@export var forced_size := 20


func _enter_tree() -> void:
	add_theme_font_size_override(&"font_size", forced_size)
