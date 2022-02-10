extends Button

const EDITOR_EXPAND_ICON := preload("res://ui/icons/fullscreen_on.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/fullscreen_off.png")
	
func _ready() -> void:
	if OS.has_feature("JavaScript"):
		# full screen does not work in the browser, this button shouldn't be used
		icon = null
		rect_min_size = Vector2(rect_min_size.x * 3, rect_min_size.y)
		return
	connect("pressed", self, "_on_pressed")
	Events.connect("fullscreen_toggled", self, "_update_icon")


func _on_pressed() -> void:
	Globals.is_fullscreen = not Globals.is_fullscreen


func _update_icon() -> void:
	icon = EDITOR_COLLAPSE_ICON if Globals.is_fullscreen else EDITOR_EXPAND_ICON
