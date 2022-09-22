extends PanelContainer

var values := [] setget set_values

onready var _label := $Label as Label
onready var _tween := $Tween as Tween


func set_values(new_values: Array) -> void:
	values = new_values
	if not is_inside_tree():
		yield(self, "ready")

	var message = PoolStringArray(new_values).join(" ")

	if _label.text == message:
		return

	_label.text = message

	_tween.stop_all()
	_tween.interpolate_property(self, "self_modulate:a", 1.0, 0.25, 1.5)
	_tween.start()
