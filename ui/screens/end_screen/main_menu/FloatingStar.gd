extends TextureRect

var duration := 1.5 + randf() * 0.5

onready var _tween := $Tween as Tween

func _ready() -> void:
	_tween.playback_speed = rand_range(0.9, 1.2)
	var top_pos := rect_position - Vector2(0, randf() * 12.0 + 4.0)
	_tween.interpolate_property(self, "rect_position", rect_position, top_pos, duration, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	_tween.interpolate_property(self, "rect_position", top_pos, rect_position, duration, Tween.TRANS_CUBIC, Tween.EASE_OUT, duration)
	_tween.start()
	_tween.seek(randf())
