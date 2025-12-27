extends Node

# Duration of the appear and disappear animations in seconds.
const TRANSITION_DURATION := 0.15
# Margin for info panel so hiding it isn't triggered by a 1px mouse move
const MOUSE_MARGIN := 25.0 * Vector2.ONE

@onready var _panel := $Panel as Control
# Makes the mouse interaction area larger than the panel.
@onready var _interaction_area := $InteractionArea as Control
@onready var _title := $Panel/MarginContainer/Column/Title as Label
@onready var _content: RichTextLabel = $Panel/MarginContainer/Column/Content

var _tween: Tween

# The timer prevents the panel from disappearing instantly when the mouse goes
# out of the area too quickly.
@onready var _timer := $Timer as Timer


func _ready() -> void:
	_panel.hide()
	_interaction_area.hide()
	_interaction_area.mouse_exited.connect(disappear)
	_timer.timeout.connect(_on_Timer_timeout)
	_content.resized.connect(_on_Content_resized)


func setup(term: String, bbcode_text: String) -> void:
	if not is_inside_tree():
		await ready
	_title.text = term
	_content.bbcode_enabled = true
	_content.text = bbcode_text



# Places the panel and interaction area based on the current mouse position,
# offsetting it vertically if it goes out of the viewport.
func align_with_mouse(global_mouse_position: Vector2) -> void:
	_panel.global_position = global_mouse_position
	var rect := _panel.get_global_rect()
	var vp_rect := _panel.get_viewport_rect()
	if rect.position.y + rect.size.y > vp_rect.size.y:
		_panel.global_position.y -= rect.size.y
	_interaction_area.global_position = _panel.global_position - MOUSE_MARGIN
	_interaction_area.size = _panel.size + MOUSE_MARGIN * 2.0


func appear() -> void:
	_panel.show()
	_interaction_area.show()

	if _tween:
		_tween.kill()

	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, TRANSITION_DURATION)
	_tween.finished.connect(_on_tween_finished)

	_timer.start()

func disappear() -> void:
	if not _timer.is_stopped():
		return

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 0.0, TRANSITION_DURATION)
	_tween.finished.connect(_on_tween_finished)


func _on_Timer_timeout() -> void:
	if not _interaction_area.get_global_rect().has_point(
		_interaction_area.get_global_mouse_position()
	):
		disappear()


func _on_tween_finished() -> void:
	if _panel.modulate.a < 0.01:
		_content.text = ""
		_panel.hide()
		_interaction_area.hide()


func _on_Content_resized() -> void:
	_panel.set_deferred("size", _panel.custom_minimum_size)
