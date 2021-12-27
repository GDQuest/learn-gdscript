class_name LessonDonePopup
extends ColorRect

signal accepted

const BACKGROUND_FADE_DURATION := 0.3
const CLASH_IN_DURATION := 0.2

export var text := "You've completed the lesson" setget set_text

onready var _layout_container := $Layout as Container
onready var _game_anchors := $Layout/GameAnchors as Control
onready var _game_container := $Layout/GameAnchors/GameContainer as Control
onready var _game_texture := (
	$Layout/GameAnchors/GameContainer/MarginContainer/GameScreen/TextureRect as TextureRect
)
onready var _message_anchors := $Layout/WellDoneAnchors as Control
onready var _message_container := $Layout/WellDoneAnchors/PanelContainer as PanelContainer

onready var _accept_button := $Layout/WellDoneAnchors/PanelContainer/Column/Margin/Column/Button as Button
onready var _label := $Layout/WellDoneAnchors/PanelContainer/Column/Margin/Column/Summary as Label
onready var _tween := $Tween as Tween


func _ready() -> void:
	set_as_toplevel(true)
	self_modulate.a = 0.0
	
	_message_anchors.rect_min_size = _message_container.rect_min_size
	var offscreen_offset := -get_viewport_rect().size.x
	_message_container.margin_left = offscreen_offset
	_message_container.margin_right = offscreen_offset

	_accept_button.connect("pressed", self, "_on_button_pressed")


func set_text(new_text: String) -> void:
	text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	_label.text = text


func fade_in(game_container: Control) -> void:
	_tween.stop_all()
	
	# Adjust the sizing to account for the game container.
	_game_anchors.rect_min_size = game_container.rect_size
	var offscreen_offset := get_viewport_rect().size.x
	_game_container.margin_left = offscreen_offset
	_game_container.margin_right = offscreen_offset
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


func _on_button_pressed() -> void:
	emit_signal("accepted")
	queue_free()
