class_name LessonDonePopup
extends ColorRect

signal pressed

const COLOR_WHITE_TRANSPARENT := Color(1.0, 1.0, 1.0, 0.0)
const BACKGROUND_FADE_DURATION := 0.4

onready var _container := $PanelContainer as PanelContainer
onready var _button := $PanelContainer/Column/Margin/Column/Button as Button
onready var _label := $PanelContainer/Column/Margin/Column/Summary as Label
onready var _tween := $Tween as Tween

export var text := "You've completed the lesson" setget set_text


func _ready() -> void:
	set_as_toplevel(true)
	_button.connect("pressed", self, "_on_button_pressed")

	_container.rect_pivot_offset = _container.rect_size / 2.0
	_container.rect_scale = Vector2.ZERO
	_container.modulate = COLOR_WHITE_TRANSPARENT
	self_modulate = COLOR_WHITE_TRANSPARENT
	_tween.interpolate_property(
		self,
		"self_modulate",
		self_modulate,
		Color.white,
		BACKGROUND_FADE_DURATION,
		Tween.TRANS_LINEAR
	)
	_tween.interpolate_property(
		_container,
		"modulate",
		_container.modulate,
		Color.white,
		0.4,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT,
		BACKGROUND_FADE_DURATION
	)
	_tween.interpolate_property(
		_container,
		"rect_scale",
		_container.rect_scale,
		Vector2.ONE,
		0.5,
		Tween.TRANS_EXPO,
		Tween.EASE_OUT,
		BACKGROUND_FADE_DURATION
	)
	_tween.start()


func _on_button_pressed() -> void:
	emit_signal("pressed")
	queue_free()


func set_text(new_text: String) -> void:
	text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	_label.text = text
