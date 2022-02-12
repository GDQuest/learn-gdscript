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
var turn_speed_degrees := 220.0
var draw_labels := true

var _points := []
var _polygons := []
var _current_offset := Vector2.ZERO
var _current_polygon: Polygon

# Keeps a list of commands the user registered. This allows us to animate the
# turtle afterwards.
var _command_stack := []

var _tween := Tween.new()
# Used to draw lines one by one
var _current_line: Line2D
var _current_line_start: Vector2

onready var _sprite := $Sprite as Sprite
onready var _canvas := $Canvas as Node2D
onready var _camera := $Camera2D as Camera2D


func _ready() -> void:
	add_child(_tween)
	# Allows to have a camera follow the turtle when using it in practices,
	# inside the GDQuestBoy.
	if get_parent() is Viewport:
		_camera.make_current()


# Virtually moves the turtle and records a new vertex.
func move_forward(distance: float) -> void:
	var previous_point := Vector2.ZERO
	if _points.empty():
		_points.append(previous_point)
	else:
		previous_point = _points[-1]
	var new_point := previous_point + Vector2.RIGHT.rotated(rotation) * distance
	new_point = new_point.snapped(Vector2.ONE)
	_points.append(new_point)

	_command_stack.append({command = "move_to", target = new_point + position + _current_offset})


func turn_right(angle_degrees: float) -> void:
	rotation_degrees = round(rotation_degrees + angle_degrees)
	_command_stack.append({command = "turn", angle = round(angle_degrees)})


func turn_left(angle_degrees: float) -> void:
	rotation_degrees = round(rotation_degrees - angle_degrees)
	_command_stack.append({command = "turn", angle = round(-angle_degrees)})
	print(_command_stack.back())


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

	rotation_degrees = 0
	_sprite.rotation_degrees = 0
	_sprite.position = Vector2.ZERO
	_points.clear()
	_polygons.clear()
	# Remove all drawn lines and labels
	for child in _canvas.get_children():
		_canvas.remove_child(child)
	_current_offset = Vector2.ZERO
	_sprite.position = Vector2.ZERO


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
	if not _points.empty():
		_close_polygon()

	position = Vector2.ZERO

	# We queue all tweens at once, based on commands: moving the turtle, turning
	# it, drawing lines...
	var tween_start_time := 0.0
	var turtle_position := Vector2.ZERO
	print(turtle_position)
	var turtle_rotation_degrees := _sprite.rotation_degrees
	for command in _command_stack:
		var duration := 1.0
		match command.command:
			"move_to":
				duration = turtle_position.distance_to(command.target) / draw_speed
				_tween.interpolate_property(
					_sprite,
					"position",
					turtle_position,
					command.target,
					duration,
					Tween.TRANS_LINEAR,
					Tween.EASE_IN,
					tween_start_time
				)
				var line := DrawingLine2D.new(
					turtle_position, command.target, duration, tween_start_time
				)
				_canvas.add_child(line)
				turtle_position = command.target
				tween_start_time += duration
			"turn":
				duration = abs(command.angle) / turn_speed_degrees
				var target_angle: float = round(turtle_rotation_degrees + command.angle)
				_tween.interpolate_property(
					_sprite,
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
				#TODO: make the turtle jump, using interpolate method?
				duration = command.offset.length() / draw_speed
				_tween.interpolate_property(
					_sprite,
					"position",
					turtle_position,
					turtle_position + command.offset,
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

	func get_center() -> Vector2:
		var rect := get_rect()
		return (rect.position + rect.end) / 2.0 + position

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
		# label_text.text = String(_current_point_index)
		label.rect_position = points[0] - label.rect_size / 2
		add_child(label)
