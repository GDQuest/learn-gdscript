extends TextureButton

export var COLOR_IDLE := Color(0.572549, 0.560784, 0.721569)
export var COLOR_HOVER := Color(0.960784, 0.980392, 0.980392)
export var COLOR_PRESSED := Color(0.455042, 0.441932, 0.621094)

var is_hovered := false setget set_is_hovered

func _ready() -> void:
	modulate = COLOR_IDLE
	connect("pressed", self, "open_gdquest_website")
	connect("button_down", self, "_toggle_shade", [true])
	connect("button_up", self, "_toggle_shade", [false])
	connect("mouse_entered", self, "set_is_hovered", [true])
	connect("mouse_exited", self, "set_is_hovered", [false])


func open_gdquest_website() -> void:
	OS.shell_open("http://gdquest.com/")


func set_is_hovered(value: bool) -> void:
	is_hovered = value
	modulate = COLOR_HOVER if value else COLOR_IDLE


func _toggle_shade(is_down: bool) -> void:
	if is_down:
		modulate = COLOR_PRESSED
	else:
		modulate = COLOR_HOVER if is_hovered() else COLOR_IDLE
