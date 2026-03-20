extends TextureButton

@export var COLOR_IDLE := Color(0.572549, 0.560784, 0.721569)
@export var COLOR_HOVER := Color(0.960784, 0.980392, 0.980392)
@export var COLOR_PRESSED := Color(0.455042, 0.441932, 0.621094)

var local_is_hovered := false:
	set(value):
		local_is_hovered = value
		modulate = COLOR_HOVER if value else COLOR_IDLE


func _ready() -> void:
	modulate = COLOR_IDLE
	connect("pressed", Callable(self, "open_gdquest_website"))
	connect("button_down", Callable(self, "_toggle_shade").bind(true))
	connect("button_up", Callable(self, "_toggle_shade").bind(false))
	connect("mouse_entered", func() -> void:
		local_is_hovered = true
	)
	connect("mouse_exited", func() -> void:
		local_is_hovered = false
	)


func open_gdquest_website() -> void:
	OS.shell_open("http://gdquest.com/")


func set_local_is_hovered(value: bool) -> void:
	modulate = COLOR_HOVER if value else COLOR_IDLE


func _toggle_shade(is_down: bool) -> void:
	if is_down:
		modulate = COLOR_PRESSED
	else:
		modulate = COLOR_HOVER if is_hovered() else COLOR_IDLE
