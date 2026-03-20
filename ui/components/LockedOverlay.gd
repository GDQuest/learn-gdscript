extends Panel

const TEXTURE_PROCESSING := preload("robot_tutor_running_code.svg")

@export var _texture_rect: TextureRect


func _ready() -> void:
	_texture_rect.texture = TEXTURE_PROCESSING
