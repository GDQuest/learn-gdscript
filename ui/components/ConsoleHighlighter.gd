class_name ConsoleHighlighter
extends Node2D

const LINE_COLORS := Color(0.40, 0.384, 0.565)
const LINE_SLICE_TICK_LIMIT := 0.005

export(Vector2) var initial_point = Vector2.ZERO
export(Vector2) var end_point = Vector2.ZERO

onready var highlight_rects : Array = [] setget set_highlight_rects

onready var _line_slice_limit := 0
onready var _baked_line_points = []
onready var _line_slice_tick := 0.0


func _ready():
	set_process(false)


func draw_curve():
	_line_slice_limit = 0
	_line_slice_tick = 0

	var curve := Curve2D.new()
	var control_point := Vector2.UP * 20

	curve.add_point(initial_point, Vector2.ZERO, control_point + Vector2.LEFT * 50)
	curve.add_point(end_point, control_point + Vector2.RIGHT * 50, Vector2.ZERO)

	_baked_line_points = curve.get_baked_points() as Array

	set_process(true)


func reset_curve():
	_line_slice_limit = 0
	_baked_line_points = []
	set_process(false)
	$Arrow.hide()
	update()


func set_highlight_rects(value) -> void:
	highlight_rects = value
	update()


func _draw() -> void:
	for rect in highlight_rects:
		draw_rect(rect, LINE_COLORS, false, 2.0, true)

	if _line_slice_limit > 0:
		draw_polyline(_baked_line_points.slice(0,_line_slice_limit), LINE_COLORS, 2, true)


func _process(delta : float) -> void:
	_line_slice_tick += delta
	while _line_slice_tick > LINE_SLICE_TICK_LIMIT:
		_line_slice_tick -= LINE_SLICE_TICK_LIMIT
		_line_slice_limit += 1
		update()

		if _line_slice_limit >= _baked_line_points.size():
			$Arrow.position = _baked_line_points[-1]
			print($Arrow.position)
			$Arrow.show()
			set_process(false)
