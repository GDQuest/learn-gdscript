extends Node2D

const LABEL_FONT := preload("res://ui/theme/fonts/font_code_small.tres")
const UNITS_MAP := {
	"robot": preload("Robot.tscn"),
	"turtle": preload("Turtle.tscn"),
}

# In Godot 4, setters and getters are defined directly on the variable
@export var board_size := Vector2(5, 3):
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
@export var draw_cell_coordinates := false

var board_size_px := cell_size * board_size
var _label_container := Control.new()

# Maps nodes to grid positions
var units: Dictionary = {}:
	set = set_units


func _ready() -> void:
	_label_container.show_behind_parent = true
	# In Godot 4, we use add_child(node) as usual
	add_child(_label_container)

	queue_redraw() # update() is now queue_redraw()
	
	set_units({
		Vector2(1, 0): "robot",
		Vector2(2, 2): "turtle",
		Vector2(3, 0): "robot",
	})


# Draws a board grid centered on the node
func _draw() -> void:
	for x in range(board_size.x):
		for y in range(board_size.y):
			var rect_pos = Vector2(x, y) * cell_size - board_size_px / 2.0
			draw_rect(Rect2(rect_pos, cell_size), Color.WHITE, false, line_width)

	if draw_cell_coordinates:
		# Clear old labels
		for label in _label_container.get_children():
			label.queue_free()

		for x in range(board_size.x):
			for y in range(board_size.y):
				var cell = Vector2(x, y)
				var label = Label.new()
				label.text = str(cell)
				# add_font_override is now add_theme_font_override
				label.add_theme_font_override("font", LABEL_FONT)
				_label_container.add_child(label)
				
				# rect_position is now position, rect_size is now size
				# Note: label.size might be (0,0) until the next frame unless sorted
				label.position = calculate_cell_position(cell) - label.size / 2.0


func set_units(new_value: Dictionary) -> void:
	units = new_value
	if not is_inside_tree():
		await ready

	# Be careful: _label_container is a child. 
	# We only want to clear the units, not the internal UI container.
	for child in get_children():
		if child != _label_container:
			child.queue_free()

	for cell in units:
		var unit_type = units[cell]
		# instance() is now instantiate()
		var unit = UNITS_MAP[unit_type].instantiate()
		add_child(unit)
		unit.position = calculate_cell_position(cell)


func calculate_cell_position(cell: Vector2) -> Vector2:
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0
