extends Button

const EDITOR_EXPAND_ICON := preload("res://ui/icons/fullscreen_on.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/fullscreen_off.png")

func _ready() -> void:
	if OS.has_feature("web"):
		modulate.a = 0.0
		return

	pressed.connect(_toggle_fullscreen)
	Events.fullscreen_toggled.connect(_toggle_fullscreen)
	_update_icon()

func _is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _toggle_fullscreen() -> void:
	var next_mode := DisplayServer.WINDOW_MODE_WINDOWED if _is_fullscreen() else DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(next_mode)
	_update_icon()

func _update_icon() -> void:
	icon = EDITOR_COLLAPSE_ICON if _is_fullscreen() else EDITOR_EXPAND_ICON
