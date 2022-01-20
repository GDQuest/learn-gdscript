class_name PracticeTestDisplay
extends Control

signal marking_finished

enum Status { IDLE, FAILED, PASSED, PENDING }

const COLOR_IDLE = Color.white
const COLOR_PASSED = Color(0.239216, 1, 0.431373)
const COLOR_FAILED = Color(1, 0.094118, 0.321569)
const COLOR_PENDING = Color(0.572549, 0.560784, 0.721569)

const FADE_TOTAL_DURATION := 0.8
const FADE_COLOR_DURATION := 0.2
const FADE_SCALE_DURATION := 0.65
const FADE_SCALE_START_AT := 2.5

var status: int = Status.IDLE setget set_status
var title := "" setget set_title

onready var _icon := $IconAnchors/Icon as TextureRect
onready var _label := $Label as Label
onready var _tweener := $Tween as Tween


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
	
	var final_color := Color.white
	match status:
		Status.PASSED:
			final_color = COLOR_PASSED
		Status.FAILED:
			final_color = COLOR_FAILED
		Status.PENDING:
			final_color = COLOR_PENDING
	
	_tweener.stop_all()
	_tweener.interpolate_property(self, "modulate", Color.white, final_color, FADE_COLOR_DURATION, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	_tweener.interpolate_property(_icon, "rect_scale:x", FADE_SCALE_START_AT, 1.0, FADE_SCALE_DURATION, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	_tweener.interpolate_property(_icon, "rect_scale:y", FADE_SCALE_START_AT, 1.0, FADE_SCALE_DURATION, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	_tweener.interpolate_callback(self, FADE_TOTAL_DURATION, "emit_signal", "marking_finished")
	_tweener.start()
