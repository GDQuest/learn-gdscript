extends Node2D


var cell := Vector2(0, 0) setget set_cell, get_cell
var cell_size := 96


func set_cell(new_cell: Vector2) -> void:
	cell = new_cell
	_animate_movement(cell, new_cell)


func get_cell() -> Vector2:
	return cell


func _animate_movement(old_cell, new_cell) -> void:
	position = new_cell * cell_size
