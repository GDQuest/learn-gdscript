extends Control

onready var squiggly := $SquigglyLine


func _ready() -> void:
	squiggly.wave_width = rect_size.x
	squiggly.position.y = rect_size.y - squiggly.WAVE_HEIGHT / 2.0 - squiggly.LINE_THICKNESS / 2.0
