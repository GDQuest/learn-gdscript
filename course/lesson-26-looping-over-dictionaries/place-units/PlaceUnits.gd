extends Node2D

@export var board_size := Vector2(5, 3): set = set_board_size
@export var cell_size := Vector2(80, 80)
@export var line_width := 4
@export var draw_cell_coordinates := false

var board_size_px := cell_size * board_size

var _placed_units := []

@onready var units_map := {
	"robot": $Robot,
	"turtle": $Turtle,
}

func _ready() -> void:
	for node in [$Robot, $Turtle]:
		node.hide()

	update()


func reset():
	for node in [$Robot, $Turtle]:
		node.hide()
	clear_units()


func _run():
	clear_units()
	run()
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")

# EXPORT run
var units = {
	Vector2(1, 0): "robot",
	Vector2(2, 2): "turtle",
	Vector2(3, 0): "robot",
}


func run():
	for cell in units:
		var unit = units[cell]
		place_unit(cell, unit)
# /EXPORT run


# Draws a board grid centered on the node
func _draw() -> void:
	for x in range(board_size.x):
		for y in range(board_size.y):
			draw_rect(Rect2(Vector2(x, y) * cell_size - board_size_px / 2.0, Vector2.ONE * cell_size), Color.WHITE, false, line_width)


func clear_units():
	for unit in _placed_units:
		unit.queue_free()


func place_unit(cell: Vector2, unit_type: String):
	if not unit_type in units_map:
		return
	var unit = units_map[unit_type].duplicate()
	unit.show()
	_placed_units.append(unit)
	add_child(unit)
	unit.position = cell_to_world(cell)


func get_displayed_units_info() -> Dictionary:
	var out := {}
	for child in _placed_units:
		var type := "robot" if child.texture == units_map.robot.texture else "turtle"
		var cell := world_to_cell(child.position)
		out[cell] = type
	return out


func cell_to_world(cell: Vector2) -> Vector2:
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0


func world_to_cell(world_position: Vector2) -> Vector2:
	return ((world_position + board_size_px / 2.0) / cell_size).floor()


func set_board_size(new_size: Vector2):
	board_size = new_size
