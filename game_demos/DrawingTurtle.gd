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

signal turtle_finished

var draw_speed := 400.0
var turn_speed_degrees := 260.0
# Increases the animation playback speed.
var speed_multiplier := 1.0

var _points := []
var _polygons := []
var _current_offset := Vector2.ZERO

# Keeps a list of commands the user registered. This allows us to animate the
# turtle afterwards.
var _command_stack := []
# Stores commands until closing a polygon, to insert commands to move the
# camera.
var _temp_command_stack = []

var _tween := Tween.new()

onready var _turn_degrees = rotation_degrees

onready var _pivot := $Pivot as Node2D
onready var _sprite := $Pivot/Sprite as Sprite
onready var _shadow := $Pivot/Shadow as Sprite
onready var _canvas := $Canvas as Node2D
onready var _camera := $Camera2D as Camera2D


func _ready() -> void:
	add_child(_tween)
	# Allows to have a camera follow the turtle when using it in practices,
	# inside the GDQuestBoy.
	if get_parent() is Viewport:
		_camera.set_as_toplevel(true)
		_camera.position = global_position
		_camera.make_current()


# Virtually moves the turtle and records a new vertex.
func move_forward(distance: float) -> void:
	var previous_point := Vector2.ZERO
	if _points.empty():
		_points.append(previous_point)
	else:
		previous_point = _points[-1]
	var new_point := previous_point + Vector2.RIGHT.rotated(deg2rad(_turn_degrees)) * distance
	new_point = new_point.snapped(Vector2.ONE)
	_points.append(new_point)

	_temp_command_stack.append(
		{command = "move_to", target = new_point + position + _current_offset}
	)


func turn_right(angle_degrees: float) -> void:
	_turn_degrees = round(_turn_degrees + angle_degrees)
	_temp_command_stack.append({command = "turn", angle = round(angle_degrees)})


func turn_left(angle_degrees: float) -> void:
	_turn_degrees = round(_turn_degrees - angle_degrees)
	_temp_command_stack.append({command = "turn", angle = round(-angle_degrees)})


# Completes the current polygon's drawing and virtually jumps the turtle to a
# new start position.
func jump(x: float, y: float) -> void:
	var last_point := Vector2.ZERO
	if not _points.empty():
		last_point = _points[-1]
	_close_polygon()
	_points.append(Vector2.ZERO)
	_current_offset += Vector2(x, y) + last_point

	_command_stack.append({command = "jump", offset = Vector2(x, y)})


# Resets the turtle's state. Use it when testing a student's assignments to
# reset the object between runs.
func reset() -> void:
	_command_stack.clear()
	stop_animation()

	rotation_degrees = 0.0
	_turn_degrees = 0.0
	_pivot.rotation_degrees = 0.0
	_pivot.position = Vector2.ZERO
	_camera.position = Vector2.ZERO
	_points.clear()
	_polygons.clear()
	for child in _canvas.get_children():
		child.queue_free()
	_current_offset = Vector2.ZERO
	_pivot.position = Vector2.ZERO


# Returns a copy of the polygons the turtle will draw.
func get_polygons() -> Array:
	return _polygons.duplicate()


func stop_animation() -> void:
	_tween.stop_all()
	for line in _canvas.get_children():
		line.stop()


# Queues all tweens required to animate the turtle drawing all the shapes and
# starts the tween animation.
func play_draw_animation() -> void:
	_close_polygon()

	# We queue all tweens at once, based on commands: moving the turtle, turning
	# it, drawing lines...
	var tween_start_time := 0.0
	var turtle_position := position
	var turtle_rotation_degrees := rotation_degrees
	for command in _command_stack:
		var duration := 1.0
		match command.command:
			"set_position":
				turtle_position = command.target
				_pivot.position = command.target
			"move_camera":
				# The callback never gets called if it has a delay of 0 seconds.
				if is_equal_approx(tween_start_time, 0.0):
					_move_camera(command.target)
				else:
					_tween.interpolate_callback(
						self, tween_start_time, "_move_camera", command.target
					)
			"move_to":
				duration = turtle_position.distance_to(command.target) / draw_speed / speed_multiplier
				_tween.interpolate_property(
					_pivot,
					"position",
					turtle_position - position,
					command.target - position,
					duration,
					Tween.TRANS_LINEAR,
					Tween.EASE_IN,
					tween_start_time
				)
				var line := DrawingLine2D.new(
					turtle_position - position,
					command.target - position,
					duration,
					tween_start_time
				)
				_canvas.add_child(line)
				turtle_position = command.target
				tween_start_time += duration
			"turn":
				duration = abs(command.angle) / turn_speed_degrees / speed_multiplier
				var target_angle: float = round(turtle_rotation_degrees + command.angle)
				_tween.interpolate_property(
					_pivot,
					"rotation_degrees",
					turtle_rotation_degrees,
					target_angle,
					duration,
					Tween.TRANS_LINEAR,
					Tween.EASE_IN,
					tween_start_time
				)
				turtle_rotation_degrees = target_angle
				tween_start_time += duration
			"jump":
				duration = 0.5 / speed_multiplier
				_tween.interpolate_property(
					_pivot,
					"position",
					turtle_position,
					turtle_position + command.offset,
					duration,
					Tween.TRANS_LINEAR,
					Tween.EASE_IN,
					tween_start_time
				)
				_tween.interpolate_method(
					self,
					"_animate_jump",
					0.0,
					1.0,
					duration,
					Tween.TRANS_LINEAR,
					Tween.EASE_IN,
					tween_start_time
				)
				turtle_position += command.offset
				tween_start_time += duration
	_tween.start()
	for line in _canvas.get_children():
		line.start()


# Animates the turtle's height and shadow scale when jumping. Tween the progress
# value from 0 to 1.
func _animate_jump(progress: float) -> void:
	var parabola := -pow(2.0 * progress - 1.0, 2.0) + 1.0
	_sprite.position.y = -parabola * 100.0
	var shadow_scale := (1.0 - parabola + 1.0) / 2.0
	_shadow.scale = shadow_scale * Vector2.ONE


# Returns the total bounding rectangle enclosing all the turtle's drawn
# polygons.
func get_rect() -> Rect2:
	var bounds := Rect2()
	for polygon in _polygons:
		var rect: Rect2 = polygon.get_rect()
		rect.position += polygon.position
		bounds = bounds.merge(rect)
	return bounds


func _close_polygon() -> void:
	if _points.empty():
		return

	var polygon := Polygon.new()
	# We want to test shapes being drawn at the correct position using the
	# position property. It works differently from jump() which offsets the
	# turtle from its position.
	polygon.position = position + _current_offset
	polygon.points = PoolVector2Array(_points)
	_polygons.append(polygon)
	_points.clear()

	if not position.is_equal_approx(Vector2.ZERO):
		_command_stack.append({command = "set_position", target = position})
	# We can't know exactly when and where to move the camera until completing a
	# shape, as we want to center the camera on the shape.
	_command_stack.append({command = "move_camera", target = polygon.get_center()})
	for command in _temp_command_stack:
		_command_stack.append(command)
	_temp_command_stack.clear()


func _move_camera(target_global_position: Vector2) -> void:
	_camera.position = target_global_position


# Polygon that can animate drawing its line.
class Polygon:
	extends Node2D

	var points := PoolVector2Array() setget , get_points

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

	func get_positioned_rect() -> Rect2:
		var rect := get_rect()
		rect.position += position
		return rect

	func get_center() -> Vector2:
		var rect := get_rect()
		return (rect.position + rect.end) / 2.0 + position

	func get_global_center() -> Vector2:
		var rect := get_rect()
		return (rect.position + rect.end) / 2.0 + global_position

	func get_points() -> PoolVector2Array:
		return points

	func is_empty():
		return points.empty() or points == PoolVector2Array([Vector2.ZERO])


class DrawingLine2D:
	extends Line2D

	const LabelScene := preload("DrawingTurtleLabel.tscn")
	const LINE_THICKNESS := 4.0
	const DEFAULT_COLOR := Color.white

	var _tween := Tween.new()

	func _init(start: Vector2, end: Vector2, duration: float, start_time: float) -> void:
		add_child(_tween)

		width = LINE_THICKNESS
		default_color = DEFAULT_COLOR
		points = PoolVector2Array([start, start])

		_tween.interpolate_callback(self, start_time, "_spawn_label")
		_tween.interpolate_method(
			self,
			"_animate_drawing",
			start,
			end,
			duration,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN,
			start_time
		)

	func start() -> void:
		_tween.start()

	func stop() -> void:
		_tween.stop_all()

	func _animate_drawing(point: Vector2) -> void:
		points[-1] = point

	func _spawn_label() -> void:
		var label := LabelScene.instance() as PanelContainer
		label.rect_position = points[0] - label.rect_size / 2
		add_child(label)
