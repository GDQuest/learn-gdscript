class_name ConsoleArrowAnimation
extends Node2D

const LINE_COLOR := Color(1, 0.96, 0.25)
const LINE_WIDTH := 3.0
const TWEEN_DURATION := 0.2

@export var initial_point := Vector2.ZERO
@export var end_point := Vector2.ZERO
@export var _arrow: Sprite2D

@onready var highlight_rects : Array = []: set = set_highlight_rects

@onready var _line_slice_limit := 0
@onready var _baked_line_points := []

var _scene_tween: Tween


func _ready():
	set_process(false)


func _draw() -> void:
	for rect in highlight_rects:
		draw_rect(rect, LINE_COLOR, false, LINE_WIDTH)# true) TODOConverter3To4 Antialiasing argument is missing

	if _line_slice_limit > 0:
		draw_polyline(_baked_line_points.slice(0, _line_slice_limit), LINE_COLOR, LINE_WIDTH, true)


func draw_curve():
	_line_slice_limit = 0

	var curve := Curve2D.new()
	var control_point := Vector2.UP * 20

	curve.add_point(initial_point, Vector2.ZERO, control_point + Vector2.LEFT * 50)
	curve.add_point(end_point, control_point + Vector2.RIGHT * 50, Vector2.ZERO)

	_baked_line_points = curve.get_baked_points() as Array

	if _scene_tween:
		_scene_tween.kill()
	_scene_tween = create_tween().set_parallel()
	_scene_tween.connect("finished", Callable(self, "_on_tween_completed"))
	_scene_tween.tween_method(Callable(self, "_on_tween_step"), 0, 1, TWEEN_DURATION)
	_scene_tween.tween_property(self, "_line_slice_limit", _baked_line_points.size(), TWEEN_DURATION).from(0)


func reset_curve():
	if _scene_tween:
		_scene_tween.stop()
	_line_slice_limit = 0
	_baked_line_points = []
	_arrow.hide()
	queue_redraw()


func set_highlight_rects(value) -> void:
	highlight_rects = value
	queue_redraw()


func _on_tween_completed():
	_arrow.position = _baked_line_points[-1]
	_arrow.show()


func _on_tween_step(_step: float):
	queue_redraw()
