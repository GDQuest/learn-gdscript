extends PanelContainer

var values := [] setget set_values

onready var _label := $Label as Label


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "self_modulate:a", 0.25, 1.5).from(1.0)


func set_values(new_values: Array) -> void:
	values = new_values
	if not is_inside_tree():
		yield(self, "ready")

	_label.text = PoolStringArray(new_values).join(" ")
