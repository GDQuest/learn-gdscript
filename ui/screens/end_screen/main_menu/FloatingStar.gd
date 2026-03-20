extends TextureRect

var duration := 1.5 + randf() * 0.5


func _ready() -> void:
	var tween := create_tween().set_parallel().set_speed_scale(randf_range(0.9, 1.2))
	
	var top_pos := position - Vector2(0, randf() * 12.0 + 4.0)
	tween.tween_property(self, "position", top_pos, duration).from(position).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", position, duration).from(top_pos).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.custom_step(randf())
