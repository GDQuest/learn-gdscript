extends Node2D

export var board_size := Vector2(6, 4) setget set_board_size
export var cell_size := Vector2(80, 80)
export var line_width := 4
export var draw_cell_coordinates := false
export var label_font: Resource

var board_size_px := cell_size * board_size

# Maps nodes to grid positions
onready var units: Dictionary setget set_units

var _label_container := Control.new()

# EXPORT path
var turtle_path = [Vector2(1, 0), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(4, 1), Vector2(5, 1), Vector2(5, 2), Vector2(5, 3)]
# /EXPORT path

onready var turtle := $Turtle


func _ready() -> void:
	_label_container.show_behind_parent = true
	add_child(_label_container)
	set_units({
		$Turtle: Vector2(0, 0),
		$Robot: Vector2(5, 3),
		$RocksGems: Vector2(2, 0),
		$RocksShield: Vector2(4, 2),
		$RocksGems2: Vector2(4, 3),
		$RocksShield2: Vector2(1, 3)
	})


func _run():
	update()
	var path = []
	for cell in turtle_path:
		path.append(calculate_cell_position(cell))
	turtle.move(path)
	yield(turtle, "goal_reached")
	Events.emit_signal("practice_run_completed")


# Draws a board grid centered on the node
func _draw() -> void:
	for x in range(board_size.x):
		for y in range(board_size.y):
			draw_rect(Rect2(Vector2(x, y) * cell_size - board_size_px / 2.0, Vector2.ONE * cell_size), Color.white, false, line_width)

	if draw_cell_coordinates:
		for label in _label_container.get_children():
			label.queue_free()

		for x in board_size.x:
			for y in board_size.y:
				var cell = Vector2(x, y)
				var label = Label.new()
				label.add_font_override("font", label_font)
				label.text = str(cell)
				_label_container.add_child(label)
				label.rect_position = calculate_cell_position(cell) - label.rect_size / 2.0


func set_units(new_value: Dictionary):
	units = new_value

	for unit in units:
		var cell: Vector2 = units[unit]
		unit.position = calculate_cell_position(cell)


func calculate_cell_position(cell: Vector2):
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0


func set_board_size(new_size: Vector2):
	board_size = new_size



