extends Panel

var cell := Vector2.ZERO setget set_cell

onready var label := $Label as Label

func set_cell(value: Vector2):
	cell = value
	if not label:
		yield(self, "ready")
	label.text = str(cell)
