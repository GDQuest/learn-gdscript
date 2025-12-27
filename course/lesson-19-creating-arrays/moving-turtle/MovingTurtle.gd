extends Node2D

# In Godot 4, setget is replaced by set() and get() blocks on the variable itself
@export var board_size := Vector2(6, 4):
	set(value):
		board_size = value
		board_size_px = cell_size * board_size
		queue_redraw() # update() is now queue_redraw()

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

@export var label_font: Font # Resource is fine, but Font is more specific for UI

var board_size_px := cell_size * board_size

# Maps nodes to grid positions
var units: Dictionary = {}:
	set(value):
		units = value
		for unit in units:
			var cell: Vector2 = units[unit]
			if unit is Node2D:
				unit.position = calculate_cell_position(cell)

var _label_container := Control.new()

# EXPORT path
# Typed arrays (Array[Vector2]) are preferred in Godot 4 for performance
var turtle_path: Array[Vector2] = [
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(2, 1),
	Vector2(3, 1),
	Vector2(4, 1),
	Vector2(5, 1),
	Vector2(5, 2),
	Vector2(5, 3)
]
# /EXPORT path

@onready var turtle := $Turtle


func _ready() -> void:
	_label_container.show_behind_parent = true
	add_child(_label_container)
	
	# Setting units manually here triggers the setter logic
	self.units = {
		$Turtle: Vector2(0, 0),
		$Robot: Vector2(5, 3),
		$RocksGems: Vector2(2, 0),
		$RocksShield: Vector2(4, 2),
		$RocksGems2: Vector2(4, 3),
		$RocksShield2: Vector2(1, 3)
	}


func _run() -> void:
	queue_redraw()
	var path: Array[Vector2] = []
	for cell in turtle_path:
		path.append(calculate_cell_position(cell))
	
	turtle.move(path)
	# yield(object, "signal") is now await object.signal
	await turtle.goal_reached
	# Godot 4 signal emission syntax
	Events.practice_run_completed.emit()


# Draws a board grid centered on the node
func _draw() -> void:
	# range() expects integers, and board_size uses floats
	for x in range(int(board_size.x)):
		for y in range(int(board_size.y)):
			var rect_pos = Vector2(x, y) * cell_size - board_size_px / 2.0
			draw_rect(Rect2(rect_pos, cell_size), Color.WHITE, false, line_width)

	if draw_cell_coordinates:
		for label in _label_container.get_children():
			label.queue_free()

		for x in range(int(board_size.x)):
			for y in range(int(board_size.y)):
				var cell = Vector2(x, y)
				var label = Label.new()
				# add_font_override -> add_theme_font_override
				label.add_theme_font_override("font", label_font)
				label.text = str(cell)
				_label_container.add_child(label)
				
				# rect_position -> position, rect_size -> size
				# Note: size may be (0,0) for one frame unless we force a refresh, 
				# but for standard Label behavior this usually works.
				label.position = calculate_cell_position(cell) - label.size / 2.0


func calculate_cell_position(cell: Vector2) -> Vector2:
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0
