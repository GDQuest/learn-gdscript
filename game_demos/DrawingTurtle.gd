# Draws geometric shapes by moving forward and turning. Inspired by the LOGO
# language.
#
# Most function calls record vertices and update the turtle's state but don't
# draw directly.
#
# To draw the shapes, see [play_draw_animation]. Uses tween animation to animate
# the motion of the turtle and drawing.
#
# Snaps drawing coordinates to the nearest pixel.
class_name DrawingTurtle
extends Node2D

const LINE_THICKNESS := 4.0
const DEFAULT_COLOR := Color.white

# Current color to draw with. Every segment registered by the turtle (when
# calling move_forward()) will use this color.
var draw_color := DEFAULT_COLOR
# Speed at which the turtle draws the line in pixels per second.
var draw_speed := 400.0

var _points := []
var _polygons := []
var _current_polygon_index := 0
var _current_offset := Vector2.ZERO

onready var _sprite = $Sprite as Sprite
onready var _canvas = $Canvas as Node2D

# Virtually moves the turtle and records a new vertex.
func move_forward(distance: float) -> void:
	var previous_point := Vector2.ZERO
	if _points.empty():
		_points.append(previous_point)
	else:
		previous_point = _points[-1]
	var new_point := previous_point + Vector2.RIGHT.rotated(rotation) * distance
	_points.append(new_point.snapped(Vector2.ONE))


func turn_right(angle_degrees: float) -> void:
	rotation_degrees = round(rotation_degrees + angle_degrees)


func turn_left(angle_degrees: float) -> void:
	rotation_degrees = round(rotation_degrees - angle_degrees)


# Completes the current polygon's drawing and virtually jumps the turtle to a
# new start position.
func jump(x: float, y: float) -> void:
	var last_point := Vector2.ZERO
	if not _points.empty():
		last_point = _points[-1]
	_close_polygon()
	_points.append(Vector2.ZERO)
	_current_offset += Vector2(x, y) + last_point


# Resets the turtle's state. Use it when testing a student's assignments to
# reset the object between runs.
func reset() -> void:
	rotation_degrees = 0
	_points.clear()
	_polygons.clear()
	draw_color = DEFAULT_COLOR
	_current_offset = Vector2.ZERO


# Starts the animation drawing every polygon inside the _polygons array.
func play_draw_animation() -> void:
	
	if not _points.empty():
		_close_polygon()
	
	if _current_polygon_index >= _polygons.size():
		return
	
	var polygon := _polygons[_current_polygon_index] as Polygon
	
	if polygon != null:
		_current_polygon_index += 1
		rotation_degrees = 0
		polygon.connect("animation_finished", self, "_polygon_finished")
		polygon.connect("current_point", self, "_polygon_updated")
		_canvas.add_child(polygon)
		polygon.start()


func _polygon_updated(point: Vector2) -> void:
	_sprite.position = point


func _polygon_finished() -> void:
	play_draw_animation()

# Returns a copy of the polygons the turtle will draw.
func get_polygons() -> Array:
	return _polygons.duplicate()


func _close_polygon() -> void:
	if _points.empty():
		return

	var polygon := Polygon.new()
	polygon.position = _current_offset
	polygon._segment.width = LINE_THICKNESS
	polygon._segment.default_color = DEFAULT_COLOR
	polygon.points = PoolVector2Array(_points)
	_polygons.append(polygon)
	_points.clear()

class Polygon extends Node2D:
	
	const LabelScene := preload("res://game_demos/DrawingTurtleLabel.tscn")
	var points := []
	var time := 3.0
	var _tween := Tween.new()
	var _segment := Line2D.new()
	var _gradient := Gradient.new()
	var _current_points := []
	var _current_point_index := 0
	var _total_distance := 0.0
	
	
	signal animation_finished()
	signal current_point(point)
	
	func _init() -> void:
		add_child(_tween)
		add_child(_segment)
		_tween.connect("tween_all_completed", self, "next")
	
	
	func start() -> void:
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
			_animation_finished()
			return
		
		var starting_point := points[_current_point_index] as Vector2
		var destination := points[_current_point_index+1] as Vector2
		_current_point_index += 1

		var distance := starting_point.distance_to(destination)
		var factor := distance / _total_distance
		var timespan := time * factor
		
		var label := LabelScene.instance() as PanelContainer
		var label_text := label.get_node("Label") as Label
		label_text.text = String(_current_point_index)
		label.rect_position = starting_point - label.rect_size / 2
		add_child(label)
		
		_current_points.append(starting_point)
		_segment.points = _current_points
		_tween.interpolate_method(self, "_animate_last_point", starting_point, destination, timespan)
		_tween.start()
	
	
	func _animate_last_point(last_point: Vector2) -> void:
		var new_points := _current_points.duplicate()
		new_points.push_back(last_point)
		_segment.points = new_points
		emit_signal("current_point", last_point)
	
	func _animation_finished() -> void:
		emit_signal("animation_finished")
	
	
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
