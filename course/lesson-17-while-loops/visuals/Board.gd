extends Node2D

@export var board_width := 3: set = set_grid_width
@export var board_height := 3: set = set_grid_height
@export var cell_size := 64
@export var line_width := 4
@export var robot_start_position := Vector2(0, 1)

var grid_size := Vector2(board_width, board_height)
# Note: Use float math for px to ensure smooth drawing
@onready var grid_size_px := Vector2(cell_size, cell_size) * grid_size

@onready var _label := $Label as Label
@onready var _robot := $Robot as Node # Cast to Node for basic access
@onready var _timer := $Timer as Timer


func _ready() -> void:
	# Godot 4 Signal Syntax
	_timer.timeout.connect(_on_timer_timeout)
	
	# Use set() to avoid warnings if the Robot script isn't a global class_name
	_robot.set("cell_size", cell_size)
	_robot.set("grid_size_px", grid_size_px)
	_robot.set("cell", robot_start_position)
	
	queue_redraw() # update() -> queue_redraw()
	_update_label()


func _draw() -> void:
	# rect_position -> position, rect_size -> size
	_label.position = (Vector2.UP * grid_size_px.y / 2.0) - Vector2(_label.size.x / 2.0, cell_size)
	
	for x: int in range(int(grid_size.x)):
		for y: int in range(int(grid_size.y)):
			var rect_pos := Vector2(x * cell_size, y * cell_size) - grid_size_px / 2.0
			draw_rect(
				Rect2(rect_pos, Vector2.ONE * cell_size), 
				Color.WHITE, 
				false, 
				line_width
			)


func set_grid_width(width: int) -> void:
	board_width = width
	grid_size.x = width
	grid_size_px = grid_size * cell_size
	if is_node_ready():
		_robot.set("grid_size_px", grid_size_px)
		queue_redraw()


func set_grid_height(height: int) -> void:
	board_height = height
	grid_size.y = height
	grid_size_px = grid_size * cell_size
	if is_node_ready():
		queue_redraw()


func _update_label() -> void:
	pass


func _on_timer_timeout() -> void:
	pass
