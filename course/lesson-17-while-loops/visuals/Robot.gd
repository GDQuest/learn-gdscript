extends Node2D


var cell := Vector2(0, 0) setget set_cell, get_cell
var cell_size := 96
var grid_size_px := Vector2.ZERO setget set_grid_size_px


func set_cell(new_cell: Vector2) -> void:
	cell = new_cell
	position = new_cell * cell_size + Vector2(cell_size/2, 12) - grid_size_px / 2.0


func get_cell() -> Vector2:
	return cell

func set_grid_size_px(value: Vector2):
	grid_size_px = value
	set_cell(cell)
