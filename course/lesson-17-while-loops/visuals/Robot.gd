class_name Robot
extends Node2D

signal cell_changed

var cell_size := 96

var grid_size_px: Vector2 = Vector2.ZERO:
	set(value):
		grid_size_px = value
		set_cell(cell)

var cell: Vector2 = Vector2(0, 0):
	set(value):
		set_cell(value)
	get:
		return cell


func set_cell(new_cell: Vector2) -> void:
	cell = new_cell
	cell.x = min(cell.x, grid_size_px.x / cell_size - 1)
	position = cell * cell_size + Vector2(cell_size / 2.0, 12.0) - grid_size_px / 2.0
	cell_changed.emit()

func set_grid_size_px(value: Vector2) -> void:
	grid_size_px = value
	
func appear() -> void:
	# Default no-op.
	# Scenes that need visuals/animations can override this behavior.
	pass
