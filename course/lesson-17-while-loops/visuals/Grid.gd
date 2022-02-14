extends Node2D

export var grid_width := 3 setget set_grid_width
export var grid_height := 3 setget set_grid_height
export var cell_size := 64
export var line_width := 4

var grid_size := Vector2(grid_width, grid_height)


func _ready() -> void:
	update()


func _draw() -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			draw_rect(Rect2(Vector2(x * cell_size, y * cell_size), Vector2.ONE * cell_size), Color.white, false, line_width)


func set_grid_width(width):
	grid_size.x = width
	update()


func set_grid_height(height):
	grid_size.y = height
	update()
