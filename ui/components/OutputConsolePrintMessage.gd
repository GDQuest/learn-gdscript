extends PanelContainer

var values := []:
	set = set_values

@export var _label: Label


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "self_modulate:a", 0.25, 1.5).from(1.0)


func set_values(new_values: Array) -> void:
	values = new_values
	if not is_inside_tree():
		await self.ready

	_label.text = " ".join(PackedStringArray(new_values))
