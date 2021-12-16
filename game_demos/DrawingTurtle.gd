# Entity that can move in a straight line and turn, drawing lines along its way.
#
# Uses tween animation to animate the motion of the turtle and drawing.
#
# Snaps drawing coordinates to the nearest pixel.
class_name DrawingTurtle
extends Node2D

const LINE_THICKNESS := 4.0
const DEFAULT_COLOR := Color.white

var draw_color := DEFAULT_COLOR setget set_draw_color

var _points := PoolVector2Array()
var _colors := PoolColorArray()

var _total_distance := 0.0
var _points_to_draw := PoolVector2Array()

onready var _tween := $Tween as Tween
onready var _sprite = $Sprite as Sprite


func _draw() -> void:
	draw_polyline_colors(_points_to_draw, _colors, LINE_THICKNESS)


func move_forward(distance: float) -> void:
	var previous_point := Vector2.ZERO
	if not _points.empty():
		previous_point = _points[-1]
	var new_point := previous_point + Vector2.RIGHT.rotated(rotation) * distance
	_points.append(new_point.snapped(Vector2.ONE))
	_colors.append(draw_color)

	_total_distance += previous_point.distance_to(new_point)


func turn_right(angle_degrees: float) -> void:
	rotation_degrees = round(rotation_degrees + angle_degrees)


func turn_left(angle_degrees: float) -> void:
	rotation_degrees = round(rotation_degrees - angle_degrees)


func reset() -> void:
	rotation_degrees = 0
	_points = PoolVector2Array()
	_colors = PoolColorArray()
	draw_color = DEFAULT_COLOR
	_total_distance = 0.0


func set_draw_color(new_color: Color) -> void:
	draw_color = new_color


func play_draw_animation() -> void:
	rotation_degrees = 0
	_tween.stop_all()
	_tween.interpolate_method(self, "_animate_drawing", 0.0, 1.0, 2.0)
	_tween.start()


func _animate_drawing(progress: float) -> void:
	_points_to_draw = PoolVector2Array([Vector2.ZERO])

	var target_distance := progress * _total_distance
	var distance := 0.0
	var previous_point := Vector2.ZERO
	for point in _points:
		var segment_length := previous_point.distance_to(point)
		if distance + segment_length >= target_distance:
			# Find final point
			var distance_ratio := (target_distance - distance) / segment_length
			var final_point: Vector2 = lerp(previous_point, point, distance_ratio).snapped(
				Vector2.ONE
			)
			_sprite.position = final_point
			_points_to_draw.append(final_point)
			break
		else:
			distance += segment_length
			_points_to_draw.append(point)
			previous_point = point
			
	update()
