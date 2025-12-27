extends ColorRect

signal accepted

const BACKGROUND_FADE_DURATION := 0.3
const CLASH_IN_DURATION := 0.2

var _raw_summary := ""

@onready var _layout_container := $Layout as Container
@onready var _game_anchors := $Layout/GameAnchors as Control
@onready var _game_container := $Layout/GameAnchors/GameContainer as Control
@onready var _game_texture := (
	$Layout/GameAnchors/GameContainer/MarginContainer/TextureRect as TextureRect
)
@onready var _message_anchors := $Layout/WellDoneAnchors as Control
@onready var _message_container := $Layout/WellDoneAnchors/PanelContainer as PanelContainer

@onready var _move_on_button := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Buttons/MoveOnButton as Button
)
@onready var _stay_button := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Buttons/StayButton as Button
)

@onready var _summary2_label := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Summary2 as RichTextLabel
)

var _tweener: Tween


func _ready() -> void:
	top_level = true
	self_modulate.a = 0.0
	
	# BBCode text is not autotranslated, so we do this to preserve the initial value.
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_summary2_label.bbcode_enabled = true
	_raw_summary = _summary2_label.text.replace("\r\n", "\n")
	_summary2_label.text = tr(_raw_summary)
	
	_message_anchors.custom_minimum_size = _message_container.custom_minimum_size
	var offscreen_offset := -get_viewport_rect().size.x
	_message_container.offset_left = offscreen_offset
	_message_container.offset_right = offscreen_offset


	_move_on_button.pressed.connect(fade_out)
	_stay_button.pressed.connect(hide)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_summary2_label):
			_summary2_label.bbcode_enabled = true
			_summary2_label.text = "[b]" + tr(_raw_summary) + "[/b]"


func fade_in(game_container: Control) -> void:
	if _tweener:
		_tweener.kill()
	
	# Adjust the sizing to account for the game container.
	_game_anchors.custom_minimum_size = game_container.custom_minimum_size
	var offscreen_offset := get_viewport_rect().size.x
	_game_container.offset_left = offscreen_offset
	_game_container.offset_right = offscreen_offset
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	# Set the texture for the output replication.
	var game_view := game_container.find_child("GameView", true, false) as GameView
	_game_texture.texture = game_view.get_game_viewport().get_texture()

	# Fade in the background.
	_tweener = create_tween()
	_tweener.tween_property(self, NodePath("self_modulate:a"), 1.0, BACKGROUND_FADE_DURATION).set_trans(Tween.TRANS_LINEAR)

	
	# Then move the message and the game together to clash at the center.
	_animate_margin(_message_container, "margin_left", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_message_container, "margin_right", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_game_container, "margin_left", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_game_container, "margin_right", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)

	_move_on_button.grab_focus()


func fade_out() -> void:
	if _tweener:
		_tweener.kill()

	# The order is opposite to fade in. First "un-clash" the message and the game view.
	var message_offscreen_offset := -get_viewport_rect().size.x
	_animate_margin(_message_container, "margin_left", message_offscreen_offset, CLASH_IN_DURATION)
	_animate_margin(_message_container, "margin_right", message_offscreen_offset, CLASH_IN_DURATION)

	var game_offscreen_offset := get_viewport_rect().size.x
	_animate_margin(_game_container, "margin_left", game_offscreen_offset, CLASH_IN_DURATION)
	_animate_margin(_game_container, "margin_right", game_offscreen_offset, CLASH_IN_DURATION)

	# Then fade out the background.
	_tweener = create_tween()
	_tweener.tween_interval(CLASH_IN_DURATION)
	_tweener.tween_property(self, NodePath("self_modulate:a"), 0.0, BACKGROUND_FADE_DURATION).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_tweener.tween_callback(Callable(self, "_on_fade_out_completed"))


func _animate_margin(control: Control, margin_name: String, to_value: float, duration: float, delay: float = 0.0) -> void:
	if not _tweener:
		_tweener = create_tween()

	if delay > 0.0:
		_tweener.tween_interval(delay)

	_tweener.tween_property(control, NodePath(margin_name), to_value, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)


func _on_fade_out_completed() -> void:
	hide()
	emit_signal("accepted")
