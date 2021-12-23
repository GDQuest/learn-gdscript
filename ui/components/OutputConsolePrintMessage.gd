extends PanelContainer

var values := [] setget set_values

onready var _label := $Label as Label
onready var _tween := $Tween as Tween


func _ready() -> void:
	_tween.stop_all()
	_tween.interpolate_property(self, "self_modulate:a", 1.0, 0.25, 1.5)
	_tween.start()


func set_values(new_values: Array) -> void:
	values = new_values
	if not is_inside_tree():
		yield(self, "ready")

	_label.text = PoolStringArray(new_values).join(" ")
