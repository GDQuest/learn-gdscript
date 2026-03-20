extends Node2D

@export var board_width := 3: set = set_grid_width
@export var board_height := 3: set = set_grid_height
@export var cell_size := 64
@export var line_width := 4
@export var robot_start_position := Vector2(0, 1)

var grid_size := Vector2(board_width, board_height)
var grid_size_px := cell_size * grid_size

@onready var _label := $Label as Label
@onready var _robot := $Robot
@onready var _timer := $Timer


func _ready() -> void:
	_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	_robot.cell_size = cell_size
	_robot.grid_size_px = grid_size_px
	_robot.cell = robot_start_position
	update()
	_update_label()


func _draw() -> void:
	_label.position = Vector2.UP * (grid_size_px) / 2 - Vector2(_label.size.x / 2, cell_size)
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			draw_rect(Rect2(Vector2(x * cell_size, y * cell_size) - grid_size_px / 2.0, Vector2.ONE * cell_size), Color.WHITE, false, line_width)


func set_grid_width(width) -> void:
	grid_size.x = width
	grid_size_px = grid_size * cell_size
	_robot.grid_size_px = grid_size_px
	update()


func set_grid_height(height) -> void:
	grid_size.y = height
	grid_size_px = grid_size * cell_size
	update()


func _update_label() -> void:
	pass


func _on_timer_timeout() -> void:
	pass

