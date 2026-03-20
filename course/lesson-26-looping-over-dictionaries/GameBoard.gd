
extends Node2D

const LABEL_FONT := preload("res://ui/theme/fonts/font_code_small.tres")
const UNITS_MAP := {
	"robot": preload("Robot.tscn"),
	"turtle": preload("Turtle.tscn"),
}

@export var board_size := Vector2(5, 3): set = set_board_size
@export var cell_size := Vector2(80, 80)
@export var line_width := 4
@export var draw_cell_coordinates := false

var board_size_px := cell_size * board_size

var _label_container := Control.new()

# Maps nodes to grid positions
@onready var units: Dictionary: set = set_units


func _ready() -> void:
	_label_container.show_behind_parent = true
	add_child(_label_container)

	update()
	set_units({
		Vector2(1, 0): "robot",
		Vector2(2, 2): "turtle",
		Vector2(3, 0): "robot",
	})


# Draws a board grid centered on the node
func _draw() -> void:
	for x in range(board_size.x):
		for y in range(board_size.y):
			draw_rect(Rect2(Vector2(x, y) * cell_size - board_size_px / 2.0, Vector2.ONE * cell_size), Color.WHITE, false, line_width)

	if draw_cell_coordinates:
		for label in _label_container.get_children():
			label.queue_free()

		for x in board_size.x:
			for y in board_size.y:
				var cell = Vector2(x, y)
				var label = Label.new()
				label.text = str(cell)
				label.add_theme_font_override("font", LABEL_FONT)
				_label_container.add_child(label)
				label.position = calculate_cell_position(cell) - label.size / 2.0


func set_units(new_value: Dictionary):
	units = new_value
	if not is_inside_tree():
		await self.ready

	for unit in get_children():
		unit.queue_free()

	for cell in units:
		var unit_type = units[cell]
		var unit = UNITS_MAP[unit_type].instantiate()
		add_child(unit)
		unit.position = calculate_cell_position(cell)


func calculate_cell_position(cell: Vector2):
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0


func set_board_size(new_size: Vector2):
	board_size = new_size

