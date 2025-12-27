extends TextureButton

@export var COLOR_IDLE := Color(0.572549, 0.560784, 0.721569)
@export var COLOR_HOVER := Color(0.960784, 0.980392, 0.980392)
@export var COLOR_PRESSED := Color(0.455042, 0.441932, 0.621094)

var hovered := false

func _ready() -> void:
	modulate = COLOR_IDLE

	pressed.connect(open_gdquest_website)
	button_down.connect(_toggle_shade.bind(true))
	button_up.connect(_toggle_shade.bind(false))
	mouse_entered.connect(set_is_hovered.bind(true))
	mouse_exited.connect(set_is_hovered.bind(false))

func open_gdquest_website() -> void:
	OS.shell_open("http://gdquest.com/")

func set_is_hovered(value: bool) -> void:
	hovered = value
	modulate = COLOR_HOVER if value else COLOR_IDLE

func _toggle_shade(is_down: bool) -> void:
	if is_down:
		modulate = COLOR_PRESSED
	else:
		modulate = COLOR_HOVER if hovered else COLOR_IDLE
