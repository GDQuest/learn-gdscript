extends Control

const FONT := preload("res://ui/theme/fonts/font_text.tres")
const TITLE_FONT := preload("res://ui/theme/fonts/font_title_slim.tres")

@export var grid_columns := 5
@export var grid_rows := 2
@export var cell_size := 120
@export var line_width := 3.0
@export var outer_line_width := 4.0

var _hovered_cell := Vector2(-1, -1)
var _grid_size_px := Vector2.ZERO
var _grid_offset := Vector2.ZERO

var _info_label: Label = null
var _grid_node: Node2D = null


func _ready() -> void:
	_grid_size_px = Vector2(grid_columns * cell_size, grid_rows * cell_size)
	custom_minimum_size = Vector2(600, 380)
	_grid_offset = Vector2(
		(600 - _grid_size_px.x) / 2.0,
		50
	)

	_grid_node = Node2D.new()
	_grid_node.position = _grid_offset
	_grid_node.connect("draw", Callable(self, "_draw_grid_content"))
	add_child(_grid_node)

	_info_label = Label.new()
	_info_label.add_theme_font_override("font", TITLE_FONT)
	_info_label.text = tr("Hover over a cell to see its pixel position")
	_info_label.align = Label.ALIGNMENT_CENTER
	_info_label.autowrap = true
	_info_label.position = Vector2(0, _grid_offset.y + _grid_size_px.y + 20)
	_info_label.size = Vector2(600, 60)
	add_child(_info_label)


func _process(_delta: float) -> void:
	var mouse_pos = get_local_mouse_position() - _grid_offset
	var new_hovered_cell = _get_cell_at_position(mouse_pos)

	if new_hovered_cell != _hovered_cell:
		_hovered_cell = new_hovered_cell
		_grid_node.update()
		_update_info_label()


func _get_cell_at_position(pos: Vector2) -> Vector2:
	if pos.x < 0 or pos.y < 0 or pos.x >= _grid_size_px.x or pos.y >= _grid_size_px.y:
		return Vector2(-1, -1)

	var cell_x = int(pos.x / cell_size)
	var cell_y = int(pos.y / cell_size)

	return Vector2(cell_x, cell_y)


func _update_info_label() -> void:
	if _hovered_cell.x < 0:
		_info_label.text = tr("Hover over a cell to see its pixel position")
	else:
		var pixel_pos = _hovered_cell * cell_size
		_info_label.text = "Cell (%d, %d) * (%d, %d) = (%d, %d) pixels" % [
			int(_hovered_cell.x),
			int(_hovered_cell.y),
			cell_size,
			cell_size,
			int(pixel_pos.x),
			int(pixel_pos.y)
		]


func _draw_grid_content() -> void:
	var bg_color = Color(0.15, 0.15, 0.22, 1.0)
	var bg_color_highlight = Color(0.25, 0.25, 0.35, 1.0)
	var line_color = Color(0.5, 0.5, 0.6, 1.0)
	var text_color = Color(0.96, 0.98, 0.98, 1.0)

	# Cell backgrounds
	for y in range(grid_rows):
		for x in range(grid_columns):
			var cell_pos = Vector2(x * cell_size, y * cell_size)
			var is_hovered = (_hovered_cell.x == x and _hovered_cell.y == y)
			var cell_color = bg_color_highlight if is_hovered else bg_color
			_grid_node.draw_rect(Rect2(cell_pos, Vector2(cell_size, cell_size)), cell_color, true)

	# grid lines
	for x in range(grid_columns + 1):
		var x_pos = x * cell_size
		var start = Vector2(x_pos, 0)
		var end = Vector2(x_pos, _grid_size_px.y)
		var width = outer_line_width if (x == 0 or x == grid_columns) else line_width
		_grid_node.draw_line(start, end, line_color, width)

	for y in range(grid_rows + 1):
		var y_pos = y * cell_size
		var start = Vector2(0, y_pos)
		var end = Vector2(_grid_size_px.x, y_pos)
		var width = outer_line_width if (y == 0 or y == grid_rows) else line_width
		_grid_node.draw_line(start, end, line_color, width)

	# Labels in the cells
	for y in range(grid_rows):
		for x in range(grid_columns):
			var cell_pos = Vector2(x * cell_size, y * cell_size)
			var cell_center = cell_pos + Vector2(cell_size, cell_size) / 2.0
			var text = "(%d, %d)" % [x, y]
			var text_size = FONT.get_string_size(text)
			var text_pos = cell_center - text_size / 2.0
			_grid_node.draw_string(FONT, text_pos, text, text_color)

	# yellow circle/position mark at top left of the cell
	# (This indicates the cell position that's calculated in the label below the grid)
	if _hovered_cell.x >= 0:
		var pixel_pos = _hovered_cell * cell_size
		var marker_color = Color(1.0, 0.8, 0.2, 1.0)
		var marker_radius = 9.0
		_grid_node.draw_circle(pixel_pos, marker_radius, marker_color)
