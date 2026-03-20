extends Node2D

const LABEL_FONT := preload("res://ui/theme/fonts/font_code_small.tres")

@export var board_size := Vector2(6, 4): set = set_board_size
@export var cell_size := Vector2(80, 80)
@export var line_width := 4
@export var draw_cell_coordinates := false

var board_size_px := cell_size * board_size

# Maps nodes to grid positions
@onready var units: Dictionary: set = set_units
# Path to draw
var _path := []

var _label_container := Control.new()


func _ready() -> void:
	_label_container.show_behind_parent = true
	add_child(_label_container)


# Draws a board grid centered on the node
func _draw() -> void:
	for x in range(board_size.x):
		for y in range(board_size.y):
			draw_rect(Rect2(Vector2(x, y) * cell_size - board_size_px / 2.0, Vector2.ONE * cell_size), Color.WHITE, false, line_width)
	draw_path(_path)

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


func draw_path(cells: Array):
	var points = PackedVector2Array()
	for cell in cells:
		points.append(calculate_cell_position(cell))

	draw_polyline(points, Color("fff540"), line_width)


func set_units(new_value: Dictionary):
	units = new_value

	for unit in units:
		var cell: Vector2 = units[unit]
		unit.position = calculate_cell_position(cell)


func calculate_cell_position(cell: Vector2):
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0


func set_board_size(new_size: Vector2):
	board_size = new_size
