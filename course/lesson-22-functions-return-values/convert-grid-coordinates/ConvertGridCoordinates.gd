tool
extends Node2D

const TEST_CELL_COORDINATES := [Vector2(0, 1), Vector2(2, 3), Vector2(5, 2)]

const COLOR_BLUE_TRANSPARENT := Color(0.1455, 0.777617, 0.97, 0.466667)
const GRID_SIZE := Vector2(6, 4)
const LINE_WIDTH := 4.0

var _draw_cells := false


func _run():
	_draw_cells = true
	update()
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")


# EXPORT run
var cell_size = Vector2(80, 80)


func convert_to_world_coordinates(cell):
	return cell * cell_size + cell_size / 2
# /EXPORT run

var _grid_size_px = GRID_SIZE * cell_size

func _draw() -> void:
	if not get("cell_size"):
		return

	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var rect := Rect2(Vector2(x, y) * cell_size - _grid_size_px / 2, cell_size)
			draw_rect(rect, Color.white, false, LINE_WIDTH)

	if _draw_cells:
		for cell in TEST_CELL_COORDINATES:
			draw_cell(cell)


func draw_cell(cell: Vector2) -> void:
	if not has_method("convert_to_world_coordinates"):
		return

	var r := Rect2(convert_to_world_coordinates(cell) - cell_size / 2 - _grid_size_px / 2, cell_size)
	draw_rect(r, COLOR_BLUE_TRANSPARENT)
