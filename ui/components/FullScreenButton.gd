extends Button

const EDITOR_EXPAND_ICON := preload("res://ui/icons/fullscreen_on.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/fullscreen_off.png")
	
func _ready() -> void:
	if OS.has_feature("JavaScript"):
		# Fullscreen does not work in the browser, so we 
		icon = null
		hint_tooltip = ""
		disabled = true
		mouse_default_cursor_shape = CURSOR_ARROW
		rect_min_size = Vector2(rect_min_size.x, rect_min_size.y)
		enabled_focus_mode = Control.FOCUS_NONE
		return

	connect("pressed", self, "_on_pressed")
	Events.connect("fullscreen_toggled", self, "_update_icon")
	_update_icon()


func _on_pressed() -> void:
	Globals.is_fullscreen = not Globals.is_fullscreen


func _update_icon() -> void:
	icon = EDITOR_COLLAPSE_ICON if Globals.is_fullscreen else EDITOR_EXPAND_ICON
