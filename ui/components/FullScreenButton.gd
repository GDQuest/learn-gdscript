extends Button

const EDITOR_EXPAND_ICON := preload("res://ui/icons/expand.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/collapse.png")


func _ready() -> void:
	connect("pressed", self, "_on_pressed")
	Events.connect("fullscreen_toggled", self, "_update_icon")


func _on_pressed() -> void:
	OS.window_fullscreen = not OS.window_fullscreen
	Events.emit_signal("fullscreen_toggled")


func _update_icon() -> void:
	icon = EDITOR_COLLAPSE_ICON if OS.window_fullscreen else EDITOR_EXPAND_ICON
