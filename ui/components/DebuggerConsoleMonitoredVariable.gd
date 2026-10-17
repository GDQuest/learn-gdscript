extends Control

var variable_name := ""

var _highlight_tween: Tween

@onready var _name_label: Label = %Name
@onready var _value_label: Label = %Value


func _ready() -> void:
	_name_label.text = variable_name


func get_name_width() -> float:
	return _name_label.get_combined_minimum_size().x


func set_name_width(width: float) -> void:
	_name_label.custom_minimum_size.x = width


func set_value(value: String, highlight_change := false) -> void:
	var has_changed := _value_label.text != value
	_value_label.text = value

	if not highlight_change:
		clear_highlight()
	elif has_changed:
		clear_highlight()
		_value_label.add_theme_color_override("font_color", Color(1, 0.96, 0.25))
		_highlight_tween = create_tween()
		_highlight_tween.tween_interval(0.8)
		_highlight_tween.tween_callback(clear_highlight)


func clear_highlight() -> void:
	if _highlight_tween != null:
		_highlight_tween.kill()
		_highlight_tween = null
	_value_label.remove_theme_color_override("font_color")
