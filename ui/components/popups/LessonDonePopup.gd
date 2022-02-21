extends ColorRect

signal accepted

const FADE_IN_DURATION := 0.25
const FADE_IN_START_SCALE := 0.5

var _raw_summary := ""

onready var _popup_container := $PanelContainer as Control
onready var _incomplete_summary := $PanelContainer/Layout/Margin/Column/IncompleteSummary as Label
onready var _move_on_button := $PanelContainer/Layout/Margin/Column/Buttons/MoveOnButton as Button
onready var _stay_button := $PanelContainer/Layout/Margin/Column/Buttons/StayButton as Button

onready var _summary_label := $PanelContainer/Layout/Margin/Column/Summary as RichTextLabel

onready var _particles := $Particles as CPUParticles2D
onready var _thick_particles := $ThickParticles as CPUParticles2D
onready var _tween := $Tween as Tween


func _ready() -> void:
	set_as_toplevel(true)
	
	# BBCode text is not autotranslated, so we do this to preserve the initial value.
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_raw_summary = _summary_label.bbcode_text.replace("\r\n", "\n")
	_summary_label.bbcode_text = tr(_raw_summary)
	
	_move_on_button.connect("pressed", self, "_on_button_pressed")
	_stay_button.connect("pressed", self, "hide")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_summary_label):
			_summary_label.bbcode_text = tr(_raw_summary)


func set_incomplete(incomplete: bool) -> void:
	_incomplete_summary.visible = incomplete


func popup_centered() -> void:
	_particles.position = rect_size / 2
	_thick_particles.position = rect_size / 2
	
	_popup_container.rect_size = _popup_container.rect_min_size
	_popup_container.rect_scale = Vector2(FADE_IN_START_SCALE, FADE_IN_START_SCALE)
	show()
	_popup_container.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_popup_container.rect_pivot_offset = _popup_container.rect_size / 2
	
	_tween.stop_all()
	_tween.interpolate_property(
		_popup_container,
		"rect_scale",
		_popup_container.rect_scale,
		Vector2(1.0, 1.0),
		FADE_IN_DURATION,
		Tween.TRANS_CUBIC
	)
	_tween.start()
	
	_move_on_button.grab_focus()


func _on_button_pressed() -> void:
	hide()
	emit_signal("accepted")
