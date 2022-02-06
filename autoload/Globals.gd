extends Node

onready var is_fullscreen := OS.window_fullscreen setget set_is_fullscreen


# Work around an issue in browsers where OS.window_fullscreen doesn't update as expected.
func set_is_fullscreen(value: bool) -> void:
	is_fullscreen = value
	OS.window_fullscreen = is_fullscreen
	Events.emit_signal("fullscreen_toggled")
