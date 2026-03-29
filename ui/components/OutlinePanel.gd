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

@export var max_border_width := 8.0:
	set = set_max_border_width
@export var border_width := 0.0:
	set = set_border_width

@onready var _border_style: StyleBoxFlat = get("theme_override_styles/panel")

var _scene_tween: Tween


func _ready() -> void:
	set_border_width(0.0)
	hide()


func appear() -> void:
	if _scene_tween:
		_scene_tween.kill()
	_scene_tween = create_tween().set_parallel()
	_scene_tween.finished.connect(_on_tween_completed)

	_scene_tween.tween_method(set_border_width, 0.0, max_border_width, ANIMATION_DURATION).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	_scene_tween.tween_property(self, "self_modulate", Color.WHITE, ANIMATION_DURATION / 2).from(COLOR_TRANSPARENT)
	show()


func disappear() -> void:
	if _scene_tween:
		_scene_tween.kill()
	_scene_tween = create_tween().set_parallel()
	_scene_tween.finished.connect(_on_tween_completed)

	_scene_tween.tween_property(self, "border_width", 0.0, ANIMATION_DURATION).from(max_border_width).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	_scene_tween.tween_property(self, "self_modulate", COLOR_TRANSPARENT, ANIMATION_DURATION / 2).from(Color.WHITE)


func set_max_border_width(new_width: float) -> void:
	max_border_width = new_width
	_border_style.border_width_left = int(new_width)
	_border_style.border_width_top = int(new_width)
	_border_style.border_width_right = int(new_width)
	_border_style.border_width_bottom = int(new_width)


func set_border_width(new_width: float) -> void:
	border_width = new_width
	_border_style.expand_margin_left = new_width
	_border_style.expand_margin_top = new_width
	_border_style.expand_margin_right = new_width
	_border_style.expand_margin_bottom = new_width


func _on_tween_completed() -> void:
	if border_width < 0.1:
		hide()
