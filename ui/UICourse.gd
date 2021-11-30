tool
extends MarginContainer

export var maximum_width := 1920.0 setget set_maximum_width
var _original_margin_left := 0.0
var _original_margin_right := 0.0


func _ready() -> void:
	connect("resized", self, "_on_margin_container_resized")
	_original_margin_left = get("custom_constants/margin_left")
	_original_margin_right = get("custom_constants/margin_right")
	_on_margin_container_resized()


func _on_margin_container_resized():
	if rect_size.x > maximum_width:
		var half_margin = (rect_size.x - maximum_width) / 2
		set("custom_constants/margin_left", half_margin)
		set("custom_constants/margin_right", half_margin)
	else:
		set("custom_constants/margin_left", _original_margin_left)
		set("custom_constants/margin_right", _original_margin_right)


func set_maximum_width(new_maximum_width: float) -> void:
	maximum_width = new_maximum_width
	_on_margin_container_resized()
