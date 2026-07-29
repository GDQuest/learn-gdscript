@tool
class_name UIBetaIndicator extends Control

signal report_requested
signal fold_state_changed(is_folded: bool)

@export var scale_open := 1.0
@export var scale_folded := 0.2
@export var is_folded := false

@onready var _background: Polygon2D = %Background
@onready var _text: Control = %Text
@onready var _chevron: TextureRect = %Chevron
@onready var _chevron_button: Button = %ChevronButton
@onready var _report_link: Label = %ReportLink

var _fold_tween: Tween
var _appear_tween: Tween


func _ready() -> void:
	set_scale_open(scale_open)
	set_scale_folded(scale_folded)
	set_is_folded(is_folded, false)

	_report_link.gui_input.connect(
		func _on_report_link_gui_input (event: InputEvent) -> void:
			if event is InputEventMouseButton:
				var mouse_event := event as InputEventMouseButton
				if (
					mouse_event.button_index == MOUSE_BUTTON_LEFT
					and mouse_event.pressed and not is_folded
				):
					report_requested.emit(),
	)
	_chevron_button.toggled.connect(
		func _on_chevron_button_toggled (is_pressed: bool) -> void:
			set_is_folded(is_pressed),
	)

	# The folded state is persisted in the user profile,
	# defer the animation so it doesn't prevent the scale animation from running.
	_animate_appear.call_deferred()


func set_scale_open(value: float) -> void:
	scale_open = maxf(value, 0.0)
	if is_inside_tree() and not is_folded:
		_background.scale = Vector2.ONE * scale_open


func set_scale_folded(value: float) -> void:
	scale_folded = clampf(value, 0.0, scale_open)
	if is_inside_tree() and is_folded:
		_background.scale = Vector2.ONE * scale_folded


func set_is_folded(value: bool, animate := true) -> void:
	var did_change := is_folded != value
	is_folded = value
	if did_change:
		fold_state_changed.emit(is_folded)
	if not is_inside_tree():
		return
	if _appear_tween and _appear_tween.is_valid():
		_appear_tween.kill()
	if animate and did_change and not Engine.is_editor_hint():
		_animate_fold()
	else:
		_apply_fold_state()


func _apply_fold_state() -> void:
	_background.scale = Vector2.ONE * (scale_folded if is_folded else scale_open)
	_text.modulate.a = 0.0 if is_folded else 1.0
	_chevron.rotation = PI if is_folded else 0.0


func _animate_appear() -> void:
	if Engine.is_editor_hint() or is_folded:
		return

	_background.modulate.a = 0.0
	_background.scale = Vector2.ZERO
	_text.modulate.a = 0.0
	_chevron.modulate.a = 0.0

	_appear_tween = create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(
		Tween.TRANS_QUAD
	)
	_appear_tween.tween_property(_background, "modulate:a", 1.0, 1.0)
	_appear_tween.tween_property(_background, "scale", Vector2.ONE * scale_open, 0.7).set_delay(0.3)
	_appear_tween.tween_property(_text, "modulate:a", 1.0, 0.7).set_delay(0.5)
	_appear_tween.parallel().tween_property(_chevron, "modulate:a", 1.0, 0.7).set_delay(0.5)


func _animate_fold() -> void:
	const FOLD_ANIMATION_DURATION := 0.25

	if _fold_tween and _fold_tween.is_valid():
		_fold_tween.kill()
	_fold_tween = create_tween().set_parallel()
	_fold_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_fold_tween.tween_property(
		_background,
		"scale",
		Vector2.ONE * (scale_folded if is_folded else scale_open),
		FOLD_ANIMATION_DURATION,
	)
	_fold_tween.tween_property(
		_text,
		"modulate:a",
		0.0 if is_folded else 1.0,
		FOLD_ANIMATION_DURATION,
	)
	_fold_tween.tween_property(
		_chevron,
		"rotation",
		PI if is_folded else 0.0,
		FOLD_ANIMATION_DURATION,
	)
