class_name ConsoleArrowAnimation
extends Node2D

const LINE_COLOR := Color(1, 0.96, 0.25)
const LINE_WIDTH := 3.0
const TWEEN_DURATION := 0.2

@export var initial_point: Vector2 = Vector2.ZERO
@export var end_point: Vector2 = Vector2.ZERO

var _highlight_rects: Array[Rect2] = []
@onready var _arrow := $Arrow as Sprite2D

var _line_slice_limit: int = 0
var _baked_line_points: PackedVector2Array = PackedVector2Array()



var _tween: Tween

func _ready() -> void:
	set_process(false)
	
func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for rect in _highlight_rects:
		draw_rect(rect, LINE_COLOR, false, LINE_WIDTH, true)

	if _line_slice_limit > 0 and not _baked_line_points.is_empty():
		draw_polyline(_baked_line_points.slice(0, _line_slice_limit), LINE_COLOR, LINE_WIDTH, true)


func draw_curve() -> void:
	_line_slice_limit = 0

	var curve := Curve2D.new()
	var control_point := Vector2.UP * 20.0

	curve.add_point(initial_point, Vector2.ZERO, control_point + Vector2.LEFT * 50.0)
	curve.add_point(end_point, control_point + Vector2.RIGHT * 50.0, Vector2.ZERO)

	_baked_line_points = curve.get_baked_points() # PackedVector2Array

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "_line_slice_limit", _baked_line_points.size(), TWEEN_DURATION)



func reset_curve() -> void:
	if _tween:
		_tween.kill()
	set_process(false)

	_line_slice_limit = 0
	_baked_line_points = PackedVector2Array()
	_arrow.hide()
	queue_redraw()

func _on_tween_finished() -> void:
	set_process(false)
	if not _baked_line_points.is_empty():
		_arrow.position = _baked_line_points[_baked_line_points.size() - 1]
	_arrow.show()
	queue_redraw()
	
func set_highlight_rects(value: Array[Rect2]) -> void:
	_highlight_rects = value
	queue_redraw()
