extends PanelContainer

var _values: Array = []
var _tween: Tween = null

@onready var _label: Label = $Label


var values: Array:
	set(v):
		set_values(v)
	get:
		return _values


func set_values(new_values: Array) -> void:
	_values = new_values
	if not is_inside_tree():
		await ready

	var parts: Array[String] = []
	for v in new_values:
		parts.append(str(v))
	var message: String = " ".join(parts)

	if _label.text == message:
		return

	_label.text = message

	if _tween != null:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", 0.25, 1.5).from(1.0)
