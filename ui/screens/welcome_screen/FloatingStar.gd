extends TextureRect

export var min_offset := 6.0
export var max_offset := 14.0

onready var offset := rand_range(min_offset, max_offset)
onready var time_offset := randf()

onready var start_position := rect_position


func _process(delta: float) -> void:
	rect_position.y = start_position.y + sin(OS.get_ticks_msec() / 1000.0 + time_offset) * offset
