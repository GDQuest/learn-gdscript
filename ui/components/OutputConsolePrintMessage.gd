extends PanelContainer


func _ready() -> void:
	var fade := create_tween()
	fade.tween_property(self, "self_modulate:a", 0.25, 1.5).from(1.0)
