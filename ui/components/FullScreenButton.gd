extends Button

const EDITOR_EXPAND_ICON := preload("res://ui/icons/fullscreen_on.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/fullscreen_off.png")


func _ready() -> void:
	connect("pressed", self, "_on_pressed")
	Events.connect("fullscreen_toggled", self, "_update_icon")


func _on_pressed() -> void:
	# Work around an issue in browsers where OS.window_fullscreen doesn't update
	# as expected.
	Globals.is_fullscreen = not Globals.is_fullscreen


func _update_icon() -> void:
	icon = EDITOR_COLLAPSE_ICON if Globals.is_fullscreen else EDITOR_EXPAND_ICON
