extends Node2D

const LINE_WIDTH := 4.0
const COLOR_SELECTED_CELL := Color(0.14902, 0.776471, 0.968627)

export var board_size := Vector2(6, 4)
export var cell_size := Vector2(80, 80)
export var label_font: Resource

var board_size_px := cell_size * board_size

# Maps cell positions to nodes
var units: Dictionary setget set_units

var selected_units := []

var _label_container := Control.new()
onready var turtle := $Turtle


func _ready() -> void:
	_label_container.show_behind_parent = true
	add_child(_label_container)
	set_units({
		Vector2(1, 0): $Robot,
		Vector2(4, 2): $Robot2,
		Vector2(0, 3): $Robot3,
		Vector2(5, 1): $Robot4,
	})


func _run():
	run()
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")


# EXPORT run
func run():
	select_units([Vector2(1, 0), Vector2(4, 2), Vector2(0, 3), Vector2(5, 1)])
# /EXPORT run


# Draws a board grid centered on the node
func _draw() -> void:
	for x in range(board_size.x):
		for y in range(board_size.y):
			draw_rect(Rect2(Vector2(x, y) * cell_size - board_size_px / 2.0, cell_size), Color.white, false, LINE_WIDTH)

	#TODO: select units
	for cell in selected_units:
		draw_rect(Rect2(units[cell].position - cell_size / 2.0, cell_size), COLOR_SELECTED_CELL, false, LINE_WIDTH)

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


func select_units(cells: Array) -> void:
	selected_units.clear()
	for cell in cells:
		if cell in units:
			selected_units.append(cell)
	update()


func set_units(new_value: Dictionary):
	units = new_value
	for cell in units:
		var unit: Node2D = units[cell]
		unit.position = calculate_cell_position(cell)


func calculate_cell_position(cell: Vector2):
	return cell * cell_size - board_size_px / 2.0 + cell_size / 2.0
