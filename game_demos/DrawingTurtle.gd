# Entity that can move in a straight line and turn, drawing lines along its way.
#
# Uses tween animation to animate the motion of the turtle and drawing.
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
var _total_distance := 0.0
var _polygons := []
var _polygons_to_draw := []
# Last registered angle stored by calling turn_right and turn_left.
var _current_angle := 0.0

onready var _tween := $Tween as Tween
onready var _sprite = $Sprite as Sprite


class Polygon:
	var points: Array
	var color: Color

	func _init(p_points: Array, p_color: Color) -> void:
		points = p_points
		color = p_color


func _draw() -> void:
	if _polygons_to_draw.empty():
		return

	for p in _polygons_to_draw:
		draw_polyline(PoolVector2Array(p.points), p.color, LINE_THICKNESS)


func move_forward(distance: float) -> void:
	var previous_point := Vector2.ZERO
	if _points.empty():
		_points.append(previous_point)
	else:
		previous_point = _points[-1]
	var new_point := previous_point + Vector2.RIGHT.rotated(rotation) * distance
	_points.append(new_point.snapped(Vector2.ONE))

	_total_distance += previous_point.distance_to(new_point)


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
	_points.append(last_point + Vector2(x, y))


func reset() -> void:
	rotation_degrees = 0
	_points.clear()
	_polygons.clear()
	draw_color = DEFAULT_COLOR
	_total_distance = 0.0


func play_draw_animation() -> void:
	if not _points.empty():
		_close_polygon()

	rotation_degrees = 0
	_tween.stop_all()
	_tween.interpolate_method(self, "_animate_drawing", 0.0, 1.0, _total_distance / draw_speed)
	_tween.start()


func _close_polygon() -> void:
	if _points.empty():
		return
	var polygon := Polygon.new(_points.duplicate(), draw_color)
	_polygons.append(polygon)
	_points.clear()


func _animate_drawing(progress: float) -> void:
	var target_distance := progress * _total_distance
	_polygons_to_draw.clear()

	var distance := 0.0
	var reached_target_distance := false
	for p in _polygons:
		var points := [p.points[0]]
		var previous_point: Vector2 = p.points[0]
		# We skip the first point as we extracted it above.
		for point in p.points.slice(1, -1):
			var segment_length := previous_point.distance_to(point)
			reached_target_distance = distance + segment_length >= target_distance
			if reached_target_distance:
				var distance_ratio := (target_distance - distance) / segment_length
				var final_point: Vector2 = lerp(previous_point, point, distance_ratio).snapped(
					Vector2.ONE
				)
				_sprite.position = final_point
				points.append(final_point)
				break
			else:
				distance += segment_length
				points.append(point)
				previous_point = point

		_polygons_to_draw.append(Polygon.new(points, draw_color))
		if reached_target_distance:
			break

	update()
