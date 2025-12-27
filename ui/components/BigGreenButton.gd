extends Button


func _ready() -> void:
	var color := Color("303049")
	add_theme_color_override("icon_color_normal", color)
	add_theme_color_override("icon_color_hover", color)
	add_theme_color_override("icon_color_focus", color)
	add_theme_color_override("icon_color_pressed", get_theme_color("font_color_pressed"))
