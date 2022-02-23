extends ColorRect

signal accepted

const BACKGROUND_FADE_DURATION := 0.3
const CLASH_IN_DURATION := 0.2

var _raw_summary := ""

onready var _layout_container := $Layout as Container
onready var _game_anchors := $Layout/GameAnchors as Control
onready var _game_container := $Layout/GameAnchors/GameContainer as Control
onready var _game_texture := (
	$Layout/GameAnchors/GameContainer/MarginContainer/TextureRect as TextureRect
)
onready var _message_anchors := $Layout/WellDoneAnchors as Control
onready var _message_container := $Layout/WellDoneAnchors/PanelContainer as PanelContainer

onready var _move_on_button := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Buttons/MoveOnButton as Button
)
onready var _stay_button := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Buttons/StayButton as Button
)

onready var _summary2_label := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Summary2 as RichTextLabel
)

onready var _tween := $Tween as Tween


func _ready() -> void:
	set_as_toplevel(true)
	self_modulate.a = 0.0
	
	# BBCode text is not autotranslated, so we do this to preserve the initial value.
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_raw_summary = _summary2_label.bbcode_text.replace("\r\n", "\n")
	_summary2_label.bbcode_text = tr(_raw_summary)
	
	_message_anchors.rect_min_size = _message_container.rect_min_size
	var offscreen_offset := -get_viewport_rect().size.x
	_message_container.margin_left = offscreen_offset
	_message_container.margin_right = offscreen_offset

	_move_on_button.connect("pressed", self, "fade_out")
	_stay_button.connect("pressed", self, "hide")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_summary2_label):
			_summary2_label.bbcode_text = tr(_raw_summary)


func fade_in(game_container: Control) -> void:
	_tween.stop_all()
	
	# Adjust the sizing to account for the game container.
	_game_anchors.rect_min_size = game_container.rect_size
	var offscreen_offset := get_viewport_rect().size.x
	_game_container.margin_left = offscreen_offset
	_game_container.margin_right = offscreen_offset
	set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_layout_container.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	# Set the texture for the output replication.
	_game_texture.texture = game_container.find_node("GameView").get_viewport().get_texture()
	
	# Fade in the background.
	_tween.interpolate_property(
		self,
		"self_modulate:a",
		0.0,
		1.0,
		BACKGROUND_FADE_DURATION,
		Tween.TRANS_LINEAR
	)
	
	# Then move the message and the game together to clash at the center.
	_animate_margin(_message_container, "margin_left", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_message_container, "margin_right", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_game_container, "margin_left", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_game_container, "margin_right", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_tween.start()

	_move_on_button.grab_focus()


func fade_out() -> void:
	_tween.stop_all()

	# The order is opposite to fade in. First "un-clash" the message and the game view.
	var message_offscreen_offset := -get_viewport_rect().size.x
	_animate_margin(_message_container, "margin_left", message_offscreen_offset, CLASH_IN_DURATION)
	_animate_margin(_message_container, "margin_right", message_offscreen_offset, CLASH_IN_DURATION)

	var game_offscreen_offset := get_viewport_rect().size.x
	_animate_margin(_game_container, "margin_left", game_offscreen_offset, CLASH_IN_DURATION)
	_animate_margin(_game_container, "margin_right", game_offscreen_offset, CLASH_IN_DURATION)
	_tween.start()

	# Then fade out the background.
	_tween.interpolate_property(
		self,
		"self_modulate:a",
		0.0,
		1.0,
		BACKGROUND_FADE_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT,
		CLASH_IN_DURATION
	)
	
	_tween.interpolate_callback(self, CLASH_IN_DURATION + BACKGROUND_FADE_DURATION, "_on_fade_out_completed")
	_tween.start()


func _animate_margin(control: Control, margin_name: String, to_value: float, duration: float, delay: float = 0.0) -> void:
	_tween.interpolate_property(
		control,
		margin_name,
		control.get(margin_name),
		to_value,
		duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT,
		delay
	)


func _on_fade_out_completed() -> void:
	hide()
	emit_signal("accepted")
