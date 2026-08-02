## This is a popup tooltip that appears when clicking a glossary term in a
## lesson.
extends Node

# Duration of the appear and disappear animations in seconds.
const TRANSITION_DURATION := 0.15
# Margin applied around the panel so it doesn't hide too abruplty; the mouse has
# to leave the panel + a margin around it to trigger hiding.
const MARGIN_FOR_HIDING_TOOLTIP := 25.0 * Vector2.ONE
# Margin from the viewport edges so the panel does not end up right at the edges of the screen.
const MARGIN_FROM_VIEWPORT_EDGES := 8.0

var scene_tween: Tween = null

@onready var _panel: Control = %Panel
# Makes the mouse interaction area larger than the panel.
@onready var _interaction_area: Control = %InteractionArea
@onready var _title: Label = %Title
@onready var _content: RichTextLabel = %Content
# The timer prevents the panel from disappearing instantly when the mouse goes
# out of the area too quickly.
@onready var _timer: Timer = %Timer


func _ready() -> void:
	_panel.hide()
	_interaction_area.hide()
	_interaction_area.mouse_exited.connect(disappear)
	_timer.timeout.connect(_on_Timer_timeout)
	_content.resized.connect(_on_Content_resized)


func setup(term: String, text: String) -> void:
	if not is_inside_tree():
		await self.ready
	_panel.show()
	_title.text = term
	_content.text = text
	_panel.hide.call_deferred()


# Places the panel and interaction area based on the current mouse position.
func align_with_mouse(global_mouse_position: Vector2) -> void:
	var panel_size := _panel.size
	var viewport_rect := _panel.get_viewport_rect()
	var viewport_start := viewport_rect.position + Vector2.ONE * MARGIN_FROM_VIEWPORT_EDGES
	var viewport_end := viewport_rect.end - Vector2.ONE * MARGIN_FROM_VIEWPORT_EDGES
	var panel_position := global_mouse_position

	# Place the panel next to the glossary term in priority. If that's not
	# possible, use the opposite side when there is not enough room. For taller
	# entries that don't fit either side (above or below the mouse cursor),
	# center them around the cursor before clamping them to the viewport.
	var available_height := viewport_end.y - viewport_start.y
	if panel_size.y > available_height:
		panel_position.y = viewport_start.y
	elif global_mouse_position.y + panel_size.y <= viewport_end.y:
		panel_position.y = global_mouse_position.y
	elif global_mouse_position.y - panel_size.y >= viewport_start.y:
		panel_position.y = global_mouse_position.y - panel_size.y
	else:
		panel_position.y = clampf(
			global_mouse_position.y - panel_size.y / 2.0,
			viewport_start.y,
			viewport_end.y - panel_size.y,
		)

	# Same logic as above for width.
	var available_width := viewport_end.x - viewport_start.x
	if panel_size.x > available_width:
		panel_position.x = viewport_start.x
	elif global_mouse_position.x + panel_size.x <= viewport_end.x:
		panel_position.x = global_mouse_position.x
	elif global_mouse_position.x - panel_size.x >= viewport_start.x:
		panel_position.x = global_mouse_position.x - panel_size.x
	else:
		panel_position.x = clampf(
			global_mouse_position.x - panel_size.x / 2.0,
			viewport_start.x,
			viewport_end.x - panel_size.x,
		)

	_panel.global_position = panel_position
	_interaction_area.global_position = _panel.global_position - MARGIN_FOR_HIDING_TOOLTIP
	_interaction_area.size = _panel.size + MARGIN_FOR_HIDING_TOOLTIP * 2


func appear() -> void:
	_panel.show()
	_interaction_area.show()

	if scene_tween:
		scene_tween.kill()

	scene_tween = create_tween()
	scene_tween.finished.connect(_on_Tween_tween_all_completed)
	scene_tween.tween_property(_panel, "modulate:a", 1.0, TRANSITION_DURATION).from(0.0)
	_timer.start()


func disappear() -> void:
	if not _timer.is_stopped():
		return

	if scene_tween:
		scene_tween.kill()
	scene_tween = create_tween()
	scene_tween.finished.connect(_on_Tween_tween_all_completed)
	scene_tween.tween_property(_panel, "modulate:a", 0.0, TRANSITION_DURATION).from(
		_panel.modulate.a
	)


func _on_Timer_timeout() -> void:
	if not _interaction_area.get_global_rect().has_point(
		_interaction_area.get_global_mouse_position(),
	):
		disappear()


func _on_Tween_tween_all_completed() -> void:
	if _panel.modulate.a < 0.01:
		_content.text = ""
		_panel.hide()
		_interaction_area.hide()


func _on_Content_resized() -> void:
	_panel.set_deferred("size", _panel.custom_minimum_size)
