class_name PracticeTestDisplay
extends Control

signal marking_finished

enum Status { IDLE, FAILED, PASSED, PENDING }

const COLOR_IDLE = Color(1.0, 1.0, 1.0)
const COLOR_PASSED = Color(0.239216, 1, 0.431373)
const COLOR_FAILED = Color(1, 0.094118, 0.321569)
const COLOR_PENDING = Color(0.572549, 0.560784, 0.721569)

const FADE_TOTAL_DURATION := 0.8
const FADE_COLOR_DURATION := 0.2
const FADE_SCALE_DURATION := 0.65
const FADE_SCALE_START_AT := 2.5

var _status: int = Status.IDLE

var status: int:
	set(value):
		set_status(value)
	get:
		return _status

var title_label := find_child("Title", true, false) as Label

@onready var _icon := $IconAnchors/Icon as TextureRect
@onready var _label := $Label as Label

var _tweener: Tween

var _title: String = "Title"

@export var title: String:
	set(value):
		set_title(value)
	get:
		return _title

func mark_as_failed(immediate: bool = false) -> void:
	set_status(Status.FAILED)
	if immediate:
		return
	
	_fade_in_status()


func mark_as_passed(immediate: bool = false) -> void:
	set_status(Status.PASSED)
	if immediate:
		return
	
	_fade_in_status()


func mark_as_pending(immediate: bool = false) -> void:
	set_status(Status.PENDING)
	if immediate:
		return
	
	_fade_in_status()


func unmark(immediate: bool = false) -> void:
	set_status(Status.IDLE)
	if immediate:
		return
	
	_fade_in_status()


func set_title(new_title: String) -> void:
	_title = new_title
	if not is_inside_tree():
		await ready
	_label.text = _title


func set_status(new_status: int) -> void:
	status = new_status
	
	if not is_inside_tree():
		await ready
	
	match status:
		Status.PASSED:
			_icon.texture = preload("res://ui/icons/checkmark_valid.svg")
			modulate = COLOR_PASSED
		Status.FAILED:
			_icon.texture = preload("res://ui/icons/checkmark_invalid.svg")
			modulate = COLOR_FAILED
		Status.PENDING:
			_icon.texture = preload("res://ui/icons/checkmark_none.svg")
			modulate = COLOR_PENDING
		_:
			_icon.texture = preload("res://ui/icons/checkmark_none.svg")
			modulate = COLOR_IDLE


func _fade_in_status() -> void:
	if not is_inside_tree():
		return

	var final_color := Color(1.0, 1.0, 1.0)
	match status:
		Status.PASSED:
			final_color = COLOR_PASSED
		Status.FAILED:
			final_color = COLOR_FAILED
		Status.PENDING:
			final_color = COLOR_PENDING

	if _tweener:
		_tweener.kill()

	_tweener = create_tween()
	_tweener.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	_tweener.tween_property(self, "modulate", final_color, FADE_COLOR_DURATION)

	_icon.scale = Vector2(FADE_SCALE_START_AT, FADE_SCALE_START_AT)
	_tweener.parallel().tween_property(_icon, "scale", Vector2.ONE, FADE_SCALE_DURATION)

	_tweener.tween_interval(FADE_TOTAL_DURATION - max(FADE_COLOR_DURATION, FADE_SCALE_DURATION))
	_tweener.tween_callback(func(): marking_finished.emit())
	
