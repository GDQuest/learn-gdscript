class_name ConsoleArrowAnimation
extends Node2D

const LINE_COLOR := Color(1, 0.96, 0.25)
const LINE_WIDTH := 3.0
const TWEEN_DURATION := 0.2

export(Vector2) var initial_point := Vector2.ZERO
export(Vector2) var end_point := Vector2.ZERO

onready var highlight_rects : Array = [] setget set_highlight_rects

onready var _arrow := $Arrow as Sprite
onready var _tween := $Tween as Tween
onready var _line_slice_limit := 0
onready var _baked_line_points := []


func _ready():
	set_process(false)
	_tween.connect("tween_completed", self, "_on_tween_completed")
	_tween.connect("tween_step", self, "_on_tween_step")


func _draw() -> void:
	for rect in highlight_rects:
		draw_rect(rect, LINE_COLOR, false, LINE_WIDTH, true)

	if _line_slice_limit > 0:
		draw_polyline(_baked_line_points.slice(0,_line_slice_limit), LINE_COLOR, LINE_WIDTH, true)


func draw_curve():
	_line_slice_limit = 0

	var curve := Curve2D.new()
	var control_point := Vector2.UP * 20

	curve.add_point(initial_point, Vector2.ZERO, control_point + Vector2.LEFT * 50)
	curve.add_point(end_point, control_point + Vector2.RIGHT * 50, Vector2.ZERO)

	_baked_line_points = curve.get_baked_points() as Array

	_tween.interpolate_property(self, "_line_slice_limit", 0, _baked_line_points.size(), TWEEN_DURATION)
	_tween.start()


func reset_curve():
	_tween.stop_all()
	_line_slice_limit = 0
	_baked_line_points = []
	_arrow.hide()
	update()


func set_highlight_rects(value) -> void:
	highlight_rects = value
	update()


func _on_tween_completed(_object : Object, _key : NodePath):
	_arrow.position = _baked_line_points[-1]
	_arrow.show()


func _on_tween_step(_object : Object, _key : NodePath, _elapsed : float, _value : Object):
	update()
