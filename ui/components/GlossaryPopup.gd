extends Node

# Duration of the appear and disappear animations in seconds.
const TRANSITION_DURATION := 0.15
# Margin for info panel so hiding it isn't triggered by a 1px mouse move
const MOUSE_MARGIN := 25.0 * Vector2.ONE

onready var _panel := $Panel as Control
# Makes the mouse interaction area larger than the panel.
onready var _interaction_area := $InteractionArea as Control
onready var _title := $Panel/MarginContainer/Column/Title as Label
onready var _content := $Panel/MarginContainer/Column/Content as RichTextLabel
onready var _tween := $Tween as Tween
# The timer prevents the panel from disappearing instantly when the mouse goes
# out of the area too quickly.
onready var _timer := $Timer as Timer


func _ready() -> void:
	_panel.hide()
	_interaction_area.hide()
	_interaction_area.connect("mouse_exited", self, "disappear")
	_timer.connect("timeout", self, "_on_Timer_timeout")
	_tween.connect("tween_all_completed", self, "_on_Tween_tween_all_completed")
	_content.connect("resized", self, "_on_Content_resized")


func setup(term: String, bbcode_text: String) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	_title.text = term
	_content.bbcode_text = bbcode_text


# Places the panel and interaction area based on the current mouse position,
# offsetting it vertically if it goes out of the viewport.
func align_with_mouse(global_mouse_position: Vector2) -> void:
	_panel.rect_global_position = global_mouse_position
	var rect := _panel.get_global_rect()
	var vp_rect := _panel.get_viewport_rect()
	if rect.position.y + rect.size.y > vp_rect.size.y:
		_panel.rect_global_position.y -= rect.size.y
	_interaction_area.rect_global_position = _panel.rect_global_position - MOUSE_MARGIN
	_interaction_area.rect_size = _panel.rect_size + MOUSE_MARGIN * 2


func appear() -> void:
	_panel.show()
	_interaction_area.show()
	_tween.stop_all()
	_tween.interpolate_property(_panel, "modulate:a", 0.0, 1.0, TRANSITION_DURATION)
	_tween.start()
	_timer.start()


func disappear() -> void:
	if not _timer.is_stopped():
		return
	_tween.stop_all()
	_tween.interpolate_property(_panel, "modulate:a", _panel.modulate.a, 0.0, TRANSITION_DURATION)
	_tween.start()


func _on_Timer_timeout() -> void:
	if not _interaction_area.get_global_rect().has_point(
		_interaction_area.get_global_mouse_position()
	):
		disappear()


func _on_Tween_tween_all_completed() -> void:
	if _panel.modulate.a < 0.01:
		_content.bbcode_text = ""
		_panel.hide()
		_interaction_area.hide()


func _on_Content_resized() -> void:
	_panel.set_deferred("rect_size", _panel.rect_min_size)
