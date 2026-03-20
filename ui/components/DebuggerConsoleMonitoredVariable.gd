extends PanelContainer

@export var _label: Label
var values := []: set = set_values



func set_values(new_values: Array) -> void:
	values = new_values
	if not is_inside_tree():
		await self.ready

	var message = " ".join(PackedStringArray(new_values))

	if _label.text == message:
		return

	_label.text = message

	var tween = create_tween()
	tween.tween_property(self, "self_modulate:a", 0.25, 1.5).from(1.0)
