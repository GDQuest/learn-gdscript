extends Button

func _ready() -> void:
	add_color_override("icon_color_normal", Color(0.188235, 0.188235, 0.286275))
	add_color_override("icon_color_hover", Color(0.188235, 0.188235, 0.286275))
	add_color_override("icon_color_focus", Color(0.188235, 0.188235, 0.286275))
	add_color_override("icon_color_pressed", get_color("font_color_pressed"))
