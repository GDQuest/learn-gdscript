tool
extends TextureRect

enum STATUS { NONE, INVALID, VALID }

export (STATUS) var status := 0 setget set_status

export var none_texture: Texture = preload("../ui/icons/none.svg")
export var valid_texture: Texture = preload("../ui/icons/valid.svg")
export var invalid_texture: Texture = preload("../ui/icons/invalid.svg")


func _init() -> void:
	texture = none_texture


func set_status(new_status: int) -> void:
	status = new_status
	match status:
		STATUS.VALID:
			texture = valid_texture
		STATUS.INVALID:
			texture = invalid_texture
		_:
			texture = none_texture
