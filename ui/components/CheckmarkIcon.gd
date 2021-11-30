class_name CheckmarkIcon
extends TextureRect

enum Status { NONE, INVALID, VALID }

var status: int = Status.NONE setget set_status


func set_status(new_status: int) -> void:
	status = new_status
	match status:
		Status.VALID:
			texture = preload("checkmark_valid.svg")
		Status.INVALID:
			texture = preload("checkmark_invalid.svg")
		_:
			texture = preload("checkmark_none.svg")
