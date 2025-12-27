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

var _points: Array[Vector2] = []
var _polygons := []
# NOTE: `var _current_offset := Vector2.ZERO` existed in the Godot 3 version to track turtle/camera
# offset during drawing. After the Godot 4 port, movement and camera updates
# rely on command data instead, so this state is no longer required.


# Keeps a list of commands the user registered. This allows us to animate the
# turtle afterwards.
var _command_stack := []
# Stores commands until closing a polygon, to insert commands to move the
# camera.
var _temp_command_stack = []
var _tween: Tween


@onready var turn_degrees: float = rotation_degrees

@onready var _pivot := $Pivot as Node2D
@onready var _sprite := $Pivot/Sprite as Sprite2D
@onready var _shadow := $Pivot/Shadow as Sprite2D
@onready var _canvas := $Canvas as Node2D
@onready var _camera := $Camera2D as Camera2D


func _ready() -> void:
	# Allows to have a camera follow the turtle when using it in practices,
	# inside the GDQuestBoy.
	if get_parent() is Viewport:
		_camera.set_as_top_level(true)
		_camera.position = global_position
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
		{command = "move_to", target = new_point})

	# Check if the polygon has vertices that align. In that case, we consider it
	# closed.
	if _points.size() > 1:
		var last_point: Vector2 = _points[-1]
		for i in range(_points.size() - 1):
			if _points[i].is_equal_approx(last_point):
				_close_polygon()
				break


func turn_right(angle_degrees: float) -> void:
	_handle_position_setting()
	turn_degrees = round(turn_degrees + angle_degrees)
	_temp_command_stack.append({command = "turn", angle = round(angle_degrees)})


func turn_left(angle_degrees: float) -> void:
	_handle_position_setting()
	turn_degrees = round(turn_degrees - angle_degrees)
	_temp_command_stack.append({command = "turn", angle = round(-angle_degrees)})


# Completes the current polygon's drawing and virtually jumps the turtle to a
# new start position.
func jump(x: float, y: float) -> void:
	_handle_position_setting()
	_close_polygon()

	position += Vector2(x, y)
	_points.append(position)
	_command_stack.append({command = "jump", offset = Vector2(x, y)})


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


# Returns a copy of the polygons the turtle will draw.
func get_polygons() -> Array:
	return _polygons.duplicate()

func stop_animation() -> void:
	if _tween:
		_tween.kill()

	for child in _canvas.get_children():
		if child is DrawingLine2D:
			(child as DrawingLine2D).stop()


# Queues all tweens required to animate the turtle drawing all the shapes and
# starts the tween animation.
func play_draw_animation() -> void:
	if _tween:
		_tween.kill()
	
	_close_polygon()
	_tween = create_tween().set_parallel(true) # Parallel to allow absolute timing via delay
	
	position = Vector2.ZERO
	# We queue all tweens at once, based on commands: moving the turtle, turning
	# it, drawing lines...
	var tween_start_time := 0.0
	var turtle_position := Vector2.ZERO
	var turtle_rotation_degrees := rotation_degrees
	
	for command in _command_stack:
		var duration := 1.0
		match command.command:
			"set_position":
				turtle_position = command.target
				_tween.tween_callback(func(): _pivot.position = command.target).set_delay(tween_start_time)
			
			"move_camera":
				_tween.tween_callback(_move_camera.bind(command.target)).set_delay(tween_start_time)
			
			"move_to":
				var target: Vector2 = command.target
				duration = turtle_position.distance_to(target) / draw_speed / speed_multiplier
				
				_tween.tween_property(_pivot, "position", command.target, duration)\
					.set_trans(Tween.TRANS_LINEAR)\
					.set_ease(Tween.EASE_IN)\
					.set_delay(tween_start_time)
				
				var line := DrawingLine2D.new(turtle_position, target, duration, tween_start_time)
				_canvas.add_child(line)
				
				turtle_position = command.target
				tween_start_time += duration
			
			"turn":
				duration = abs(command.angle) / turn_speed_degrees / speed_multiplier
				var target_angle: float = round(turtle_rotation_degrees + command.angle)
				
				_tween.tween_property(_pivot, "rotation_degrees", target_angle, duration)\
					.set_trans(Tween.TRANS_LINEAR)\
					.set_ease(Tween.EASE_IN)\
					.set_delay(tween_start_time)
				
				turtle_rotation_degrees = target_angle
				tween_start_time += duration
			
			"jump":
				duration = 0.5 / speed_multiplier
				_tween.tween_property(_pivot, "position", turtle_position + command.offset, duration)\
					.set_trans(Tween.TRANS_LINEAR)\
					.set_ease(Tween.EASE_IN)\
					.set_delay(tween_start_time)
				
				_tween.tween_method(_animate_jump, 0.0, 1.0, duration)\
					.set_trans(Tween.TRANS_LINEAR)\
					.set_ease(Tween.EASE_IN)\
					.set_delay(tween_start_time)
					
				turtle_position += command.offset
				tween_start_time += duration

	# Start all line animations
	for child: Node in _canvas.get_children():
		if child is DrawingLine2D:
			(child as DrawingLine2D).stop()

# Returns the total bounding rectangle enclosing all the turtle's drawn
# polygons.
func get_rect() -> Rect2:
	var bounds := Rect2()
	for polygon: Polygon in _polygons:
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
	_command_stack.append({command = "move_camera", target = center})
	for command in _temp_command_stack:
		_command_stack.append(command)
	_temp_command_stack.clear()


func _handle_position_setting() -> void:
	if _points.is_empty() and position.is_equal_approx(Vector2.ZERO):
		return

	var previous_point: Vector2 = Vector2.ZERO
	if not _points.is_empty():
		previous_point = _points[-1] as Vector2
	if not position.is_equal_approx(previous_point):
		_temp_command_stack.append({command = "set_position", target = position})
		_close_polygon()
		_points.append(position)

func _move_camera(target_global_position: Vector2) -> void:
	_camera.position = target_global_position

# Polygon that can animate drawing its line.
class Polygon extends Node2D:
	var _points: PackedVector2Array = PackedVector2Array()

	var points: PackedVector2Array:
		set(value): _points = value
		get: return _points

	func get_rect() -> Rect2:
		var top_left := Vector2.ZERO
		var bottom_right := Vector2.ZERO
		for p in _points:
			if p.x > bottom_right.x: bottom_right.x = p.x
			elif p.x < top_left.x: top_left.x = p.x
			if p.y > bottom_right.y: bottom_right.y = p.y
			elif p.y < top_left.y: top_left.y = p.y
		return Rect2(top_left, bottom_right - top_left)

class DrawingLine2D extends Line2D:
	const LabelScene := preload("DrawingTurtleLabel.tscn")
	const LINE_THICKNESS := 4.0
	const DEFAULT_COLOR := Color.WHITE

	var _tween: Tween
	var _start: Vector2
	var _end: Vector2
	var _duration: float
	var _start_time: float

	func _init(start_pos: Vector2, end_pos: Vector2, duration: float, start_time: float) -> void:
		_start = start_pos
		_end = end_pos
		_duration = duration
		_start_time = start_time
		
		width = LINE_THICKNESS
		default_color = DEFAULT_COLOR
		points = PackedVector2Array([_start, _start])

	func start() -> void:
		if _tween: _tween.kill()
		_tween = create_tween().set_parallel(true)
		
		_tween.tween_callback(_spawn_label).set_delay(_start_time)
		_tween.tween_method(_animate_drawing, _start, _end, _duration)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_ease(Tween.EASE_IN)\
			.set_delay(_start_time)

	func stop() -> void:
		if _tween: _tween.kill()

	func _animate_drawing(point: Vector2) -> void:
		points[1] = point

	func _spawn_label() -> void:
		var label := LabelScene.instantiate() as PanelContainer
		add_child(label)
		# Needs a frame for size to calculate
		await get_tree().process_frame
		label.position = _start - label.size / 2
