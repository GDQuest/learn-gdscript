extends Node2D

export var board_width := 3 setget set_grid_width
export var board_height := 3 setget set_grid_height
export var cell_size := 64
export var line_width := 4

var grid_size := Vector2(board_width, board_height)

onready var _label := $Label
onready var _robot := $Robot
onready var _timer := $Timer


func _ready() -> void:
	_timer.connect("timeout", self, "_on_timer_timeout")
	_robot.cell_size = cell_size
	_robot.cell = Vector2(0, 1)
	update()


func _draw() -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			draw_rect(Rect2(Vector2(x * cell_size, y * cell_size), Vector2.ONE * cell_size), Color.white, false, line_width)


func set_grid_width(width) -> void:
	grid_size.x = width
	_update_label()
	update()


func set_grid_height(height) -> void:
	grid_size.y = height
	_update_label()
	update()


func _update_label() -> void:
	pass


func _on_timer_timeout() -> void:
	pass

