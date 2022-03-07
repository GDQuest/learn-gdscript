extends Button


func _ready() -> void:
	var color := Color("303049")
	add_color_override("icon_color_normal", color)
	add_color_override("icon_color_hover", color)
	add_color_override("icon_color_focus", color)
	add_color_override("icon_color_pressed", get_color("font_color_pressed"))
