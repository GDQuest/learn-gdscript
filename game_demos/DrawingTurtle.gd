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

var _points := []
var _polygons := []
var _current_offset := Vector2.ZERO
var _current_polygon: Polygon
# If false, stop playing an active animation.
var _is_playing := false

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
	_is_playing = false
	rotation_degrees = 0
	_points.clear()
	_polygons.clear()
	_current_offset = Vector2.ZERO


# Returns a copy of the polygons the turtle will draw.
func get_polygons() -> Array:
	return _polygons.duplicate()


func stop_animation() -> void:
	_is_playing = false
	if _current_polygon:
		_current_polygon.stop_animation()


# Starts the animation drawing every polygon inside the _polygons array.
func play_draw_animation() -> void:
	_is_playing = true
	if not _points.empty():
		_close_polygon()

	for polygon in _polygons:
		if not _is_playing:
			break

		_current_polygon = polygon
		polygon = polygon as Polygon
		if not polygon:
			continue

		rotation_degrees = 0.0
		polygon.connect("line_end_moved", self, "_change_sprite_position")
		_canvas.add_child(polygon)
		polygon.start_draw_animation()
		yield(polygon, "animation_finished")

	_current_polygon = null


func _change_sprite_position(new_position: Vector2) -> void:
	_sprite.position = new_position


func _close_polygon() -> void:
	if _points.empty():
		return

	var polygon := Polygon.new()
	polygon.position = _current_offset
	polygon.line_2d.width = LINE_THICKNESS
	polygon.line_2d.default_color = DEFAULT_COLOR
	polygon.points = PoolVector2Array(_points)
	_polygons.append(polygon)
	_points.clear()


# Polygon that can animate drawing its line.
class Polygon:
	extends Node2D

	const LabelScene := preload("DrawingTurtleLabel.tscn")
	var points := []
	var draw_speed := 400.0
	var line_2d := Line2D.new()
	var _tween := Tween.new()
	var _current_points := []
	var _current_point_index := 0
	var _total_distance := 0.0

	signal animation_finished
	signal line_end_moved(new_coordinates)

	func _init() -> void:
		add_child(_tween)
		add_child(line_2d)
		_tween.connect("tween_all_completed", self, "next")

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

		var starting_point := points[_current_point_index] as Vector2
		var destination := points[_current_point_index + 1] as Vector2
		_current_point_index += 1

		var distance := starting_point.distance_to(destination)
		var animation_duration := distance / draw_speed

		var label := LabelScene.instance() as PanelContainer
		var label_text := label.get_node("Label") as Label
		label_text.text = String(_current_point_index)
		label.rect_position = starting_point - label.rect_size / 2
		add_child(label)

		_current_points.append(starting_point)
		line_2d.points = _current_points
		_tween.interpolate_method(
			self, "_animate_point_position", starting_point, destination, animation_duration
		)
		_tween.start()

	func stop_animation() -> void:
		_tween.stop_all()

	func _animate_point_position(point: Vector2) -> void:
		var new_points := _current_points.duplicate()
		new_points.push_back(point)
		line_2d.points = new_points
		emit_signal("line_end_moved", point)

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

	func get_points() -> Array:
		return points.duplicate()
