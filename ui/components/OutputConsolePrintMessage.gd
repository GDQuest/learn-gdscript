extends PanelContainer
class_name OutputConsolePrintMessage

var values: Array = []:
	set(value):
		set_values(value)

@onready var _label: Label = $Label

var _tween: Tween


func _ready() -> void:
	_restart_tween()


func _restart_tween() -> void:
	if _tween:
		_tween.kill()

	# "self_modulate" exists on CanvasItem; PanelContainer inherits it.
	# Use tween_property + NodePath for subproperty "a".
	_tween = create_tween()
	_tween.tween_property(self, NodePath("self_modulate:a"), 0.25, 1.5)


func set_values(new_values: Array) -> void:
	values = new_values
	if not is_inside_tree():
		await ready

	# Convert to strings safely, then join.
	var parts: PackedStringArray = PackedStringArray()
	for v in new_values:
		parts.append(str(v))
	_label.text = " ".join(parts)

	_restart_tween()
