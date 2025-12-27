extends TextureRect

@export var min_offset: float = 6.0
@export var max_offset: float = 14.0

@onready var offset: float = randf_range(min_offset, max_offset)
@onready var time_offset: float = randf()

@onready var start_position: Vector2 = position

func _process(_delta: float) -> void:
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	position.y = start_position.y + sin(t + time_offset) * offset
