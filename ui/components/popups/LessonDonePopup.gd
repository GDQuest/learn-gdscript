class_name LessonDonePopup
extends ColorRect

signal accepted

const FADE_IN_DURATION := 0.25
const FADE_IN_START_SCALE := 0.5

var _raw_summary := ""

@onready var _popup_container := $PanelContainer as Control
@onready var _incomplete_summary := $PanelContainer/Layout/Margin/Column/IncompleteSummary as Label
@onready var _move_on_button := $PanelContainer/Layout/Margin/Column/Buttons/MoveOnButton as Button
@onready var _stay_button := $PanelContainer/Layout/Margin/Column/Buttons/StayButton as Button

@onready var _summary_label := $PanelContainer/Layout/Margin/Column/Summary as RichTextLabel

@onready var _particles := $Particles as CPUParticles2D
@onready var _thick_particles := $ThickParticles as CPUParticles2D

# In Godot 4, we store the Tween object, not a Tween node
var _tween: Tween


func _ready() -> void:
	# set_as_toplevel is now a property: top_level
	top_level = true
	
	# BBCode text in Godot 4 is just 'text'. 
	# Note: Ensure 'bbcode_enabled' is true in the Inspector for this node.
	_raw_summary = _summary_label.text.replace("\r\n", "\n")
	_summary_label.text = tr(_raw_summary)
	
	# Signal syntax
	_move_on_button.pressed.connect(_on_button_pressed)
	_stay_button.pressed.connect(hide)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_summary_label):
			_summary_label.text = tr(_raw_summary)


func set_incomplete(incomplete: bool) -> void:
	_incomplete_summary.visible = incomplete


func popup_centered() -> void:
	# 'size' refers to the ColorRect's size
	_particles.position = size / 2
	_thick_particles.position = size / 2
	
	# Update Control properties (rect_ prefixes removed)
	_popup_container.size = _popup_container.custom_minimum_size
	_popup_container.scale = Vector2(FADE_IN_START_SCALE, FADE_IN_START_SCALE)
	
	show()
	
	# set_anchors_and_margins_preset -> set_anchors_and_offsets_preset
	_popup_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_popup_container.pivot_offset = _popup_container.size / 2
	
	# Godot 4 Tween API
	if _tween:
		_tween.kill()
	_tween = create_tween()
	
	_tween.tween_property(
		_popup_container, 
		"scale", 
		Vector2.ONE, 
		FADE_IN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	_move_on_button.grab_focus()


func _on_button_pressed() -> void:
	hide()
	accepted.emit()
