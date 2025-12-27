extends TextureRect

var duration := 1.5 + randf() * 0.5

func _ready() -> void:
	var start_pos := position
	
	var top_pos := start_pos - Vector2(0, randf() * 12.0 + 4.0)
	
	var tween := create_tween().set_loops()
	
	tween.set_speed_scale(randf_range(0.9, 1.2))
	
	tween.tween_property(self, "position", top_pos, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_property(self, "position", start_pos, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.custom_step(randf() * duration * 2.0)
