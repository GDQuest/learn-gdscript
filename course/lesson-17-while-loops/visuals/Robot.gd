extends Node2D


signal cell_changed

var cell := Vector2(0, 0): get = get_cell, set = set_cell
var cell_size := 96
var grid_size_px := Vector2.ZERO: set = set_grid_size_px


func set_cell(new_cell: Vector2) -> void:
	cell = new_cell
	cell.x = min(cell.x, grid_size_px.x / cell_size - 1)
	position = cell * cell_size + Vector2(cell_size/2, 12) - grid_size_px / 2.0
	emit_signal("cell_changed")


func get_cell() -> Vector2:
	return cell


func set_grid_size_px(value: Vector2):
	grid_size_px = value
	set_cell(cell)
