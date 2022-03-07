extends MarginContainer

var cell_size := Vector2.ONE * 120

onready var label := $VBoxContainer/Label as Label
onready var grid := $VBoxContainer/CenterContainer/GridContainer as GridContainer


func _ready() -> void:
	var index := 0
	for cell in grid.get_children():
		var coords = Vector2(index % grid.columns, floor(index / grid.columns))
		cell.connect("mouse_entered", self, "update_position", [coords])
		cell.cell = coords
		index += 1


func update_position(cell: Vector2):
	label.text = "Cell world position: " + str(cell * cell_size + cell_size / 2)
