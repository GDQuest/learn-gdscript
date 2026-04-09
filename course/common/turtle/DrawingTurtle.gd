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

@export var _pivot: Node2D
@export var _sprite: Sprite2D
@export var _shadow: Sprite2D
@export var _canvas: Node2D
@export var _camera: Camera2D

var draw_speed := 400.0
var turn_speed_degrees := 260.0
# Increases the animation playback speed.
var speed_multiplier := 1.0

var _points: Array[Vector2] = []
var _polygons: Array[Polygon] = []

# Keeps a list of commands the user registered. This allows us to animate the
# turtle afterwards.
var _command_stack := []
# Stores commands until closing a polygon, to insert commands to move the
# camera.
var _temp_command_stack = []

var _scene_tween: Tween

@onready var turn_degrees := rotation_degrees


func _ready() -> void:
	# Allows to have a camera follow the turtle when using it in practices,
	# inside the GDQuestBoy.
	if get_parent() is SubViewport:
		_camera.set_as_top_level(true)
		_camera.position = global_position
		_camera.enabled = true
		_camera.make_current()


# Virtually moves the turtle and records a new vertex.
func move_forward(distance: float) -> void:
	_handle_position_setting()
	if _points.is_empty():
		_points.append(Vector2.ZERO)

	var new_point := position + Vector2.RIGHT.rotated(deg_to_rad(turn_degrees)) * distance
	new_point = new_point.snapped(Vector2.ONE)
	_points.append(new_point)
	position = new_point

	_temp_command_stack.append(
		{ command = "move_to", target = new_point },
	)

	# Check if the polygon has vertices that align. In that case, we consider it
	# closed.
	if _points.size() > 1:
		var last_point := _points[-1]
		for i: int in range(_points.size() - 1):
			if _points[i].is_equal_approx(last_point):
				_close_polygon()
				break


func turn_right(angle_degrees: float) -> void:
	_handle_position_setting()
	turn_degrees = round(turn_degrees + angle_degrees)
	_temp_command_stack.append({ command = "turn", angle = round(angle_degrees) })


func turn_left(angle_degrees: float) -> void:
	_handle_position_setting()
	turn_degrees = round(turn_degrees - angle_degrees)
	_temp_command_stack.append({ command = "turn", angle = round(-angle_degrees) })


# Completes the current polygon's drawing and virtually jumps the turtle to a
# new start position.
func jump(x: float, y: float) -> void:
	_handle_position_setting()
	_close_polygon()

	position += Vector2(x, y)
	_points.append(position)

	_command_stack.append({ command = "jump", offset = Vector2(x, y) })


# Resets the turtle's state. Use it when testing a student's assignments to
# reset the object between runs.
func reset() -> void:
	_command_stack.clear()
	stop_animation()
	_animate_jump(0)

	rotation_degrees = 0.0
	turn_degrees = 0.0
	_pivot.rotation_degrees = 0.0
	_pivot.position = Vector2.ZERO
	_camera.position = Vector2.ZERO
	_points.clear()
	_polygons.clear()
	for child in _canvas.get_children():
		child.queue_free()
	position = Vector2.ZERO
	_pivot.position = Vector2.ZERO


# Returns a copy of the polygons the turtle will draw.
func get_polygons() -> Array[Polygon]:
	return _polygons.duplicate()


func stop_animation() -> void:
	if _scene_tween:
		_scene_tween.kill()
	for line: DrawingLine2D in _canvas.get_children():
		line.stop()


# Queues all tweens required to animate the turtle drawing all the shapes and
# starts the tween animation.
func play_draw_animation() -> void:
	_close_polygon()

	position = Vector2.ZERO
	# We queue all tweens at once, based on commands: moving the turtle, turning
	# it, drawing lines...
	var tween_start_time := 0.0
	var turtle_position := Vector2.ZERO
	var turtle_rotation_degrees := rotation_degrees
	_scene_tween = create_tween().set_parallel()
	for command in _command_stack:
		var duration := 1.0
		match command.command:
			"set_position":
				turtle_position = command.target
				_pivot.position = command.target
			"move_camera":
				# The callback never gets called if it has a delay of 0 seconds.
				if is_equal_approx(tween_start_time, 0.0):
					var command_target: Vector2 = command.target
					_move_camera(command_target)
				else:
					_scene_tween.tween_callback(_move_camera.bind(command.target)).set_delay(tween_start_time)
			"move_to":
				var command_target: Vector2 = command.target
				duration = turtle_position.distance_to(command_target) / draw_speed / speed_multiplier
				_scene_tween.tween_property(_pivot, "position", command.target, duration).from(turtle_position).set_ease(Tween.EASE_IN).set_delay(tween_start_time)
				var line := DrawingLine2D.new(
					turtle_position,
					command_target,
					duration,
					tween_start_time,
					get_tree(),
				)
				_canvas.add_child(line)
				turtle_position = command.target
				tween_start_time += duration
			"turn":
				duration = abs(command.angle) / turn_speed_degrees / speed_multiplier
				var target_angle: float = round(turtle_rotation_degrees + command.angle)
				_scene_tween.tween_property(_pivot, "rotation_degrees", target_angle, duration).from(turtle_rotation_degrees).set_ease(Tween.EASE_IN).set_delay(tween_start_time)
				turtle_rotation_degrees = target_angle
				tween_start_time += duration
			"jump":
				duration = 0.5 / speed_multiplier
				_scene_tween.tween_property(_pivot, "position", turtle_position + command.offset, duration).from(turtle_position).set_ease(Tween.EASE_IN).set_delay(tween_start_time)
				_scene_tween.tween_method(_animate_jump, 0.0, 1.0, duration).set_ease(Tween.EASE_IN).set_delay(tween_start_time)
				turtle_position += command.offset
				tween_start_time += duration
	for line: DrawingLine2D in _canvas.get_children():
		line.start()
	_scene_tween.tween_callback(turtle_finished.emit).set_delay(tween_start_time)


# Returns the total bounding rectangle enclosing all the turtle's drawn
# polygons.
func get_rect() -> Rect2:
	var bounds := Rect2()
	for polygon in _polygons:
		var rect: Rect2 = polygon.get_rect()
		rect.position += polygon.position
		bounds = bounds.merge(rect)
	return bounds


func get_command_stack() -> Array:
	return _command_stack.duplicate()


# Animates the turtle's height and shadow scale when jumping. Tween the progress
# value from 0 to 1.
func _animate_jump(progress: float) -> void:
	var parabola := -pow(2.0 * progress - 1.0, 2.0) + 1.0
	_sprite.position.y = -parabola * 100.0
	var shadow_scale := (1.0 - parabola + 1.0) / 2.0
	_shadow.scale = shadow_scale * Vector2.ONE


func _close_polygon() -> void:
	if _points.size() <= 1:
		_points.clear()
		for command in _temp_command_stack:
			_command_stack.append(command)
		_temp_command_stack.clear()
		return

	var polygon := Polygon.new()
	# We want to test shapes being drawn at the correct position using the
	# position property. It works differently from jump() which offsets the
	# turtle from its position.
	polygon.position = position
	polygon.points = PackedVector2Array(_points)
	_polygons.append(polygon)
	var center := Vector2.ZERO
	if not _points.is_empty():
		var bounds := Rect2(_points[0], Vector2.ZERO)
		for point in _points:
			bounds = bounds.expand(point)
			center = bounds.position + bounds.size / 2.0
	_points.clear()
	# We can't know exactly when and where to move the camera until completing a
	# shape, as we want to center the camera on the shape.
	_command_stack.append({ command = "move_camera", target = center })
	for command in _temp_command_stack:
		_command_stack.append(command)
	_temp_command_stack.clear()


func _handle_position_setting() -> void:
	# When the user accesses and adjusts the position variable directly, we must
	# detect this, close the polygon, and add to the command stack.
	if _points.is_empty() and position.is_equal_approx(Vector2.ZERO):
		return

	var previous_point := Vector2.ZERO
	if not _points.is_empty():
		previous_point = _points[-1]
	if not position.is_equal_approx(previous_point):
		_temp_command_stack.append({ command = "set_position", target = position })
		_close_polygon()
		_points.append(position)


func _move_camera(target_global_position: Vector2) -> void:
	_camera.position = target_global_position


# Polygon that can animate drawing its line.
class Polygon:
	extends Node2D

	var points := PackedVector2Array():
		get = get_points


	# Returns the local bounds of the polygon. That is to say, it only takes the
	# point into account in local space, but not the polygon's `position`.
	func get_rect() -> Rect2:
		var top_left := Vector2.ZERO
		var bottom_right := Vector2.ZERO
		var local_points = get_points()
		for p in local_points:
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


	func get_points() -> PackedVector2Array:
		var local_points = []
		var first_point = Vector2.ZERO
		if not points.is_empty():
			first_point = points[0]

		for point in points:
			local_points.append(point - first_point)
		return local_points


	func is_empty():
		return points.is_empty() or points == PackedVector2Array([Vector2.ZERO])


class DrawingLine2D:
	extends Line2D

	const LabelScene := preload("DrawingTurtleLabel.tscn")
	const LINE_THICKNESS := 4.0
	const DEFAULT_COLOR := Color.WHITE

	var _tween: Tween


	func _init(start_point: Vector2, end: Vector2, duration: float, start_time: float, tree: SceneTree) -> void:
		width = LINE_THICKNESS
		default_color = DEFAULT_COLOR
		points = PackedVector2Array([start_point, start_point])

		_tween = tree.create_tween().set_parallel().bind_node(self)
		_tween.tween_callback(_spawn_label).set_delay(start_time)
		_tween.tween_method(_animate_drawing, start_point, end, duration).set_ease(Tween.EASE_IN).set_delay(start_time)


	func start() -> void:
		_tween.play()


	func stop() -> void:
		_tween.stop()


	func _animate_drawing(point: Vector2) -> void:
		points[-1] = point


	func _spawn_label() -> void:
		var label := LabelScene.instantiate() as PanelContainer
		label.position = points[0] - label.size / 2
		add_child(label)
