class_name PracticeTestDisplay
extends Control

enum Status { IDLE, FAILED, PASSED }

const COLOR_PASSED = Color(0.239216, 1, 0.431373)
const COLOR_FAILED = Color(1, 0.094118, 0.321569)

var status: int = Status.IDLE setget set_status
var title := "" setget set_title

onready var _icon := $Icon as TextureRect
onready var _label := $Label as Label


func mark_as_failed() -> void:
	set_status(Status.FAILED)


func mark_as_passed() -> void:
	set_status(Status.PASSED)


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
