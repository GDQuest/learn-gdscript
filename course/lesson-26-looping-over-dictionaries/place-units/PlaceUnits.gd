extends Node2D

@export var board_size := Vector2(5, 3):
	set(value):
		board_size = value
		# Update the pixel calculation whenever the board size changes
		board_size_px = cell_size * board_size
		queue_redraw()

@export var cell_size := Vector2(80, 80):
	set(value):
		cell_size = value
		board_size_px = cell_size * board_size
		queue_redraw()

@export var line_width := 4
@export var draw_cell_coordinates := false

# Logic for board pixels
var board_size_px := cell_size * board_size

var _placed_units: Array[Node2D] = []

@onready var units_map := {
	"robot": $Robot,
	"turtle": $Turtle,
}

func _ready() -> void:
	# Hide the template nodes
	$Robot.hide()
	$Turtle.hide()
	queue_redraw() # update() is now queue_redraw()


func reset() -> void:
	$Robot.hide()
	$Turtle.hide()
	clear_units()


func _run() -> void:
	clear_units()
	run()
	await get_tree().create_timer(0.5).timeout
	# Godot 4 signal syntax
	Events.practice_run_completed.emit()

# EXPORT run
var units := {
	Vector2(1, 0): "robot",
	Vector2(2, 2): "turtle",
	Vector2(3, 0): "robot",
}


func run() -> void:
	for cell in units:
		var unit_type: String = units[cell]
		place_unit(cell, unit_type)
# /EXPORT run


# Draws a board grid centered on the node
func _draw() -> void:
	for x in range(int(board_size.x)):
		for y in range(int(board_size.y)):
			var rect_pos = Vector2(x, y) * cell_size - board_size_px / 2.0
			draw_rect(Rect2(rect_pos, cell_size), Color.WHITE, false, line_width)


func clear_units() -> void:
	for unit in _placed_units:
		if is_instance_valid(unit):
			unit.queue_free()
	_placed_units.clear()


func place_unit(cell: Vector2, unit_type: String) -> void:
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
		# Assuming child is a Sprite2D or similar with a texture property
		var type := "robot" if child.texture == units_map.robot.texture else "turtle"
		var cell := world_to_cell(child.position)
		out[cell] = type
	return out


func cell_to_world(cell: Vector2) -> Vector2:
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0


func world_to_cell(world_position: Vector2) -> Vector2:
	return ((world_position + board_size_px / 2.0) / cell_size).floor()
