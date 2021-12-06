extends Control

enum Status { IDLE, FAILED, PASSED }

const COLOR_PASSED = Color("#26c6f7")
const COLOR_FAILED = Color("#fff540")

var status: int = Status.IDLE setget set_status
var title := "" setget set_title

onready var _icon := $Icon as TextureRect
onready var _label := $Label as Label


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	_label.text = new_title


func set_status(new_status: int) -> void:
	status = new_status
	if not is_inside_tree():
		yield(self, "ready")
	match status:
		Status.PASSED:
			_icon.texture = preload("checkmark_valid.svg")
			modulate = COLOR_PASSED
		Status.FAILED:
			_icon.texture = preload("checkmark_invalid.svg")
			modulate = COLOR_FAILED
		_:
			_icon.texture = preload("checkmark_none.svg")
			modulate = Color.white
