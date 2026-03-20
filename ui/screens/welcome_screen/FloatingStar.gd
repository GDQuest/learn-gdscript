extends TextureRect

@export var min_offset := 6.0
@export var max_offset := 14.0

@onready var offset := randf_range(min_offset, max_offset)
@onready var time_offset := randf()

@onready var start_position := position


func _process(delta: float) -> void:
	position.y = start_position.y + sin(Time.get_ticks_msec() / 1000.0 + time_offset) * offset
