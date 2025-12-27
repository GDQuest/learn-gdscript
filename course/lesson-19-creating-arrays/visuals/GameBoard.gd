extends Node2D

const LABEL_FONT := preload("res://ui/theme/fonts/font_code_small.tres")

# Godot 4 uses set(value) blocks instead of setget
@export var board_size := Vector2(6, 4):
	set(value):
		board_size = value
		board_size_px = cell_size * board_size
		queue_redraw()

@export var cell_size := Vector2(80, 80):
	set(value):
		cell_size = value
		board_size_px = cell_size * board_size
		queue_redraw()

@export var line_width := 4
@export var draw_cell_coordinates := false:
	set(value):
		draw_cell_coordinates = value
		queue_redraw()

var board_size_px := cell_size * board_size

# Maps nodes to grid positions
var units: Dictionary = {}:
	set(value):
		units = value
		for unit in units:
			var cell: Vector2 = units[unit]
			if unit is Node2D:
				unit.position = calculate_cell_position(cell)

# Path to draw
var _path: Array = []:
	set(value):
		_path = value
		queue_redraw()

var _label_container := Control.new()


func _ready() -> void:
	_label_container.show_behind_parent = true
	add_child(_label_container)


# Draws a board grid centered on the node
func _draw() -> void:
	for x in range(int(board_size.x)):
		for y in range(int(board_size.y)):
			var rect_pos = Vector2(x, y) * cell_size - board_size_px / 2.0
			draw_rect(Rect2(rect_pos, cell_size), Color.WHITE, false, line_width)
	
	if _path.size() > 1:
		draw_path(_path)

	if draw_cell_coordinates:
		# Clear old labels
		for label in _label_container.get_children():
			label.queue_free()

		for x in range(int(board_size.x)):
			for y in range(int(board_size.y)):
				var cell = Vector2(x, y)
				var label = Label.new()
				label.text = str(cell)
				# add_font_override -> add_theme_font_override
				label.add_theme_font_override("font", LABEL_FONT)
				_label_container.add_child(label)
				# rect_position -> position, rect_size -> size
				label.position = calculate_cell_position(cell) - label.size / 2.0


func draw_path(cells: Array) -> void:
	# PoolVector2Array -> PackedVector2Array
	var points := PackedVector2Array()
	for cell in cells:
		points.append(calculate_cell_position(cell))

	if points.size() > 1:
		draw_polyline(points, Color("fff540"), line_width)


func calculate_cell_position(cell: Vector2) -> Vector2:
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0
