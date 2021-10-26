# Displays an animated border around a panel-based UI component.
#
# Animates the border using a stylebox's expand margin as the border properties
# use integers, causing choppy animation.
#
# As a result, to make it work, we display the border behind the parent. Append
# as a child of a PanelContainer or simular container encompassing a whole UI
# component.
extends Panel

const COLOR_TRANSPARENT := Color(1.0, 1.0, 1.0, 0.0)
const ANIMATION_DURATION := 0.6

export var max_border_width := 8.0 setget set_max_border_width
export var border_width := 0.0 setget set_border_width

var _border_style: StyleBoxFlat = get("custom_styles/panel")

onready var _tween := $Tween as Tween


func appear() -> void:
	_tween.stop_all()
	_tween.interpolate_method(
		self,
		"set_border_width",
		0.0,
		max_border_width,
		ANIMATION_DURATION,
		Tween.TRANS_CIRC,
		Tween.EASE_OUT
	)
	_tween.start()
	_tween.seek(0.0)


func disappear() -> void:
	_tween.stop_all()
	_tween.interpolate_property(
		self,
		"border_width",
		max_border_width,
		0.0,
		ANIMATION_DURATION,
		Tween.TRANS_CIRC,
		Tween.EASE_IN
	)
	_tween.start()
	_tween.seek(0.0)


func set_max_border_width(new_width: float) -> void:
	_border_style.border_width_left = new_width
	_border_style.border_width_top = new_width
	_border_style.border_width_right = new_width
	_border_style.border_width_bottom = new_width


func set_border_width(new_width: float) -> void:
	_border_style.expand_margin_left = new_width
	_border_style.expand_margin_top = new_width
	_border_style.expand_margin_right = new_width
	_border_style.expand_margin_bottom = new_width
