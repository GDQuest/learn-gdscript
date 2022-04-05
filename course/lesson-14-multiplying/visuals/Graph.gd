tool
extends Path2D

const COLOR_GREY := Color("928fb8")

export var graph_size := Vector2.ONE * 250
export var text_x := "x-axis"
export var text_y := "y-axis"
export var axis_increments := 50
export var show_speed := 400

var _line
var _points := []
var _last_point := Vector2.ZERO
# Need a draw offset as the scene is centered in lessons
var _draw_offset := Vector2(-graph_size.x / 2, graph_size.y/2)

onready var _label_x := $LabelX as Label
onready var _label_y := $LabelY as Label


func _ready() -> void:
	update()

	if Engine.editor_hint:
		return

	_label_x.rect_position += _draw_offset
	_label_x.rect_size.x = graph_size.x
	_label_x.text = text_x
	_label_y.rect_position += _draw_offset
	_label_y.rect_size.x = graph_size.y
	_label_y.text = text_y

	_points = curve.tessellate(5, 4)
	_line = Polygon.new(show_speed)
	_line.position = _draw_offset
	_line.line_2d.width = 3
	_line.line_2d.default_color = Color.white
	_line.connect("line_end_moved", self, "_change_sprite_position")
	add_child(_line)
	
	_last_point = _points[0] + _draw_offset


func run() -> void:
	if _line.is_drawing():
		return

	_line.reset()
	_line.points = _points
	_line.start_draw_animation()


func reset() -> void:
	_line.reset()
	_last_point = Vector2(0, 0)


func _process(_delta: float) -> void:
	if Engine.editor_hint:
		return
	
	update()


func _change_sprite_position(new_position: Vector2) -> void:
	_last_point = new_position


func _draw() -> void:
	# Don't offset the graph in the editor as drawing curves won't line up
	var draw_offset = Vector2.ZERO if Engine.editor_hint else _draw_offset

	draw_line(Vector2.ZERO + draw_offset, Vector2(graph_size.x, 0) + draw_offset, COLOR_GREY, 4, true)
	draw_line(Vector2.ZERO + draw_offset, Vector2(0, -graph_size.y) + draw_offset, COLOR_GREY, 4, true)
	
	for i in range(graph_size.x / axis_increments):
		draw_circle(Vector2(axis_increments + i * axis_increments, 0) + draw_offset, 4, Color.white)
	for i in range(graph_size.y / axis_increments):
		draw_circle(-Vector2(0, axis_increments + i * axis_increments) + draw_offset, 4, Color.white)
	
	if _last_point != Vector2(0, 0):
		draw_circle(_last_point, 4, Color.white)


class Polygon:
	extends Node2D

	var points := PoolVector2Array() setget , get_points
	var draw_speed := 400.0
	var line_2d := Line2D.new()
	var _tween := Tween.new()
	var _current_points := PoolVector2Array()
	var _current_point_index := 0
	var _total_distance := 0.0

	signal animation_finished
	signal line_end_moved(new_coordinates)

	func _init(line_draw_speed := 400.0) -> void:
		add_child(_tween)
		add_child(line_2d)
		_tween.connect("tween_all_completed", self, "next")
		draw_speed = line_draw_speed

	func reset() -> void:
		stop_animation()
		line_2d.clear_points()
		_current_point_index = 0
		_total_distance = 0
		_current_points.resize(0)

	func start_draw_animation() -> void:
		var previous_point := points[0] as Vector2
		for index in range(1, points.size()):
			var p := points[index] as Vector2
			var distance = previous_point.distance_to(p)
			previous_point = p
			_total_distance += distance
		_tween.stop_all()
		next()

	func next() -> void:
		if points.size() - _current_point_index < 2:
			emit_signal("animation_finished")
			return

		var starting_point: Vector2 = points[_current_point_index]
		var destination: Vector2 = points[_current_point_index + 1]
		_current_point_index += 1

		var distance := starting_point.distance_to(destination)
		var animation_duration := distance / draw_speed

		_current_points.append(starting_point)
		line_2d.points = _current_points
		_tween.interpolate_method(
			self, "_animate_point_position", starting_point, destination, animation_duration
		)
		_tween.start()

	func stop_animation() -> void:
		_tween.remove_all()

	func is_drawing() -> bool:
		return _tween.is_active()

	func _animate_point_position(point: Vector2) -> void:
		var new_points := _current_points
		new_points.push_back(point)
		line_2d.points = new_points
		emit_signal("line_end_moved", point + position)

	# Returns the local bounds of the polygon. That is to say, it only takes the
	# point into account in local space, but not the polygon's `position`.
	func get_rect() -> Rect2:
		var top_left := Vector2.ZERO
		var bottom_right := Vector2.ZERO
		for p in points:
			if p.x > bottom_right.x:
				bottom_right.x = p.x
			elif p.x < top_left.x:
				top_left.x = p.x

			if p.y > bottom_right.y:
				bottom_right.y = p.y
			elif p.y < top_left.y:
				top_left.y = p.y
		return Rect2(top_left, bottom_right - top_left)

	func get_center() -> Vector2:
		var rect := get_rect()
		return (rect.position + rect.end) / 2.0 + position

	func get_points() -> PoolVector2Array:
		return points
