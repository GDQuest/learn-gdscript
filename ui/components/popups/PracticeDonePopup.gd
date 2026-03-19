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

var _scene_tween: SceneTreeTween


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
	if _scene_tween:
		_scene_tween.kill()
	
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
	_scene_tween = create_tween().set_parallel()
	_scene_tween.tween_property(self, "self_modulate:a", 1.0, BACKGROUND_FADE_DURATION).from(0.0)
	
	# Then move the message and the game together to clash at the center.
	_animate_margin(_message_container, "margin_left", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_message_container, "margin_right", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_game_container, "margin_left", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)
	_animate_margin(_game_container, "margin_right", 0.0, CLASH_IN_DURATION, BACKGROUND_FADE_DURATION)

	_move_on_button.grab_focus()


func fade_out() -> void:
	if _scene_tween:
		_scene_tween.kill()
	
	_scene_tween = create_tween().set_parallel()

	# The order is opposite to fade in. First "un-clash" the message and the game view.
	var message_offscreen_offset := -get_viewport_rect().size.x
	_animate_margin(_message_container, "margin_left", message_offscreen_offset, CLASH_IN_DURATION)
	_animate_margin(_message_container, "margin_right", message_offscreen_offset, CLASH_IN_DURATION)

	var game_offscreen_offset := get_viewport_rect().size.x
	_animate_margin(_game_container, "margin_left", game_offscreen_offset, CLASH_IN_DURATION)
	_animate_margin(_game_container, "margin_right", game_offscreen_offset, CLASH_IN_DURATION)

	# Then fade out the background.
	_scene_tween.chain().tween_property(self, "self_modulate:a", 1.0, BACKGROUND_FADE_DURATION).from(0.0)
	
	_scene_tween.tween_callback(self, "_on_fade_out_completed").set_delay(CLASH_IN_DURATION + BACKGROUND_FADE_DURATION)


func _animate_margin(control: Control, margin_name: String, to_value: float, duration: float, delay: float = 0.0) -> void:
	_scene_tween.tween_property(control, margin_name, to_value, duration).from(control.get(margin_name)).set_ease(Tween.EASE_OUT)


func _on_fade_out_completed() -> void:
	hide()
	emit_signal("accepted")
