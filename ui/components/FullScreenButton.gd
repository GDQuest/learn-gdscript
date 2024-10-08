extends Button

const EDITOR_EXPAND_ICON := preload("res://ui/icons/fullscreen_on.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/fullscreen_off.png")

func _ready() -> void:
	if OS.has_feature("JavaScript"):
		modulate.a = 0.0
		return

	connect("pressed", self, "_toggle_fullscreen")
	Events.connect("fullscreen_toggled", self, "_toggle_fullscreen")
	_update_icon()


func _toggle_fullscreen() -> void:
	OS.window_fullscreen = not OS.window_fullscreen
	_update_icon()


func _update_icon():
	icon = EDITOR_COLLAPSE_ICON if OS.window_fullscreen else EDITOR_EXPAND_ICON
