extends Button

const EDITOR_EXPAND_ICON := preload("res://ui/icons/fullscreen_on.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/fullscreen_off.png")

func _ready() -> void:
	if OS.has_feature("JavaScript"):
		modulate.a = 0.0
		return

	connect("pressed", Callable(self, "_toggle_fullscreen"))
	Events.connect("fullscreen_toggled", Callable(self, "_toggle_fullscreen"))
	_update_icon()


func _toggle_fullscreen() -> void:
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (not ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
	_update_icon()


func _update_icon():
	icon = EDITOR_COLLAPSE_ICON if ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)) else EDITOR_EXPAND_ICON
