extends PanelContainer

var values := [] setget set_values

onready var _label := $Label as Label

var _tween: SceneTreeTween


func set_values(new_values: Array) -> void:
	values = new_values
	if not is_inside_tree():
		yield(self, "ready")

	var message = PoolStringArray(new_values).join(" ")

	if _label.text == message:
		return

	_label.text = message

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", 0.25, 1.5).from(1.0)
