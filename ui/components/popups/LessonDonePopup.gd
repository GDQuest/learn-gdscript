extends ColorRect

signal accepted

var _raw_summary := ""

@onready var _panel_container: Control = %PanelContainer
@onready var _center_container: CenterContainer = %CenterContainer
@onready var _incomplete_summary: Label = %IncompleteSummary
@onready var _move_on_button: Button = %MoveOnButton
@onready var _stay_button: Button = %StayButton

@onready var _summary_label: RichTextLabel = %Summary

@onready var _particles: CPUParticles2D = %Particles
@onready var _thick_particles: CPUParticles2D = %ThickParticles


func _ready() -> void:
	set_as_top_level(true)

	# BBCode text is not autotranslated, so we do this to preserve the initial value.
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_raw_summary = _summary_label.text.replace("\r\n", "\n")
	_summary_label.text = tr(_raw_summary)

	_move_on_button.pressed.connect(_on_button_pressed)
	_stay_button.pressed.connect(hide)
	visibility_changed.connect(
		func _on_visibility_changed() -> void:
			_center_container.visible = visible,
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_summary_label):
			_summary_label.text = tr(_raw_summary)


func set_incomplete(is_incomplete: bool) -> void:
	_incomplete_summary.visible = is_incomplete


func popup_centered() -> void:
	_particles.position = size / 2
	_thick_particles.position = size / 2

	const FADE_IN_START_SCALE := 0.5
	_panel_container.scale = Vector2(FADE_IN_START_SCALE, FADE_IN_START_SCALE)
	show()
	_center_container.show()
	_panel_container.pivot_offset = _panel_container.size / 2

	const FADE_IN_DURATION := 0.25
	var scene_tween := create_tween()
	scene_tween \
			.tween_property(_panel_container, "scale", Vector2(1.0, 1.0), FADE_IN_DURATION) \
			.from(_panel_container.scale) \
			.set_trans(Tween.TRANS_CUBIC)

	_move_on_button.grab_focus()


func _on_button_pressed() -> void:
	hide()
	accepted.emit()
