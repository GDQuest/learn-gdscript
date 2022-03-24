extends Panel

const TEXTURE_PROCESSING := preload("robot_tutor_running_code.svg")

onready var _texture_rect := $Layout/TextureRect as TextureRect


func _ready() -> void:
	_texture_rect.texture = TEXTURE_PROCESSING
