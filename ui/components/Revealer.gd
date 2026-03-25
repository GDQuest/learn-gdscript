@tool
@icon("./Revealer.svg")
class_name Revealer
extends Container

const ANIMATION_ICON_DURATION := 0.1
const ANIMATION_REVEAL_DURATION := 0.24

const TOGGLE_OPACITY := 0.65
const TOGGLE_OPACITY_HOVER := 1.0

signal expanded

@export var title := "Expand": set = set_title
@export var is_expanded := false: set = set_is_expanded

@export var title_font_color: Color = Color.WHITE: set = set_title_font_color
@export var title_icon_color: Color = Color.WHITE: set = set_title_icon_color
@export var title_font: Font: set = set_title_font
@export var title_panel: StyleBox: set = set_title_panel
@export var title_panel_expanded: StyleBox: set = set_title_panel_expanded

@export var content_panel: StyleBox: set = set_content_panel
@export var content_separation: int = 2: set = set_content_separation

@export var _toggle_bar: PanelContainer
@export var _toggle_button: Button
@export var _toggle_label: Label
@export var _toggle_icon_anchor: Control
@export var _toggle_icon: TextureRect

var _content_children := []
var _percent_revealed := 0.0
var _title_style: StyleBox
var _scene_tween: Tween


func _ready() -> void:
	size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	_toggle_label.text = title
	_toggle_button.button_pressed = is_expanded
	_index_content()
	_update_icon_anchor()
	_update_theme()

	_toggle_bar.modulate.a = TOGGLE_OPACITY

	_toggle_button.mouse_entered.connect(_on_toggle_entered)
	_toggle_button.mouse_exited.connect(_on_toggle_exited)
	_toggle_button.toggled.connect(_on_toggle_pressed)

	_toggle_content(is_expanded, true)
	_title_style = get_title_panel_style()

	child_entered_tree.connect(_on_child_added)
	child_exiting_tree.connect(_on_child_removed)


func _draw() -> void:
	var title_size := _toggle_bar.size

	if _title_style:
		var title_rect := Rect2()
		title_rect.position = Vector2(0, 0)
		# Use rect_size.x (Revealer's width) instead of _toggle_bar.rect_size.x
		# to avoid drawing a narrow background when _toggle_bar hasn't been resized yet
		title_rect.size.x = size.x
		title_rect.size.y = _toggle_bar.size.y + _title_style.get_minimum_size().y
		draw_style_box(_title_style, title_rect)

		title_size += _title_style.get_minimum_size()

	if content_panel:
		var content_rect := Rect2()
		content_rect.position = Vector2(0, title_size.y)
		content_rect.size = Vector2(size.x, size.y - title_size.y)
		draw_style_box(content_panel, content_rect)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_resort()


func _index_content() -> void:
	_content_children = []

	for child_node in get_children():
		var control_node := child_node as Control
		if not control_node or control_node == _toggle_bar:
			continue

		_content_children.append(control_node)


func _update_icon_anchor() -> void:
	if not is_inside_tree():
		return

	_toggle_icon_anchor.custom_minimum_size = _toggle_icon.size
	_toggle_icon.pivot_offset = _toggle_icon.size / 2


func _update_theme() -> void:
	if not is_inside_tree():
		return

	_toggle_label.add_theme_font_override("font", title_font)
	_toggle_label.add_theme_color_override("font_color", title_font_color)
	_toggle_icon.modulate = title_icon_color


func _on_child_added(child_node: Node) -> void:
	var control_node := child_node as Control
	if not control_node or control_node == _toggle_bar:
		return

	_content_children.append(control_node)


func _on_child_removed(child_node: Node) -> void:
	if _content_children.has(child_node):
		_content_children.erase(child_node)


func _get_minimum_size() -> Vector2:
	# Title/toggle bar always contributes to the minimal size in full.
	var title_size := Vector2.ZERO
	if is_instance_valid(_toggle_bar):
		title_size = _toggle_bar.get_combined_minimum_size()

	if _title_style:
		title_size += _title_style.get_minimum_size()

	# Content can be partially visible, so we calculate full size, then slice it.
	var content_size := Vector2.ZERO

	var first := true
	for child_node in get_children():
		var control_node := child_node as Control
		if not control_node or not control_node.is_visible_in_tree():
			continue
		if control_node == _toggle_bar:
			continue

		var control_size := control_node.get_combined_minimum_size()
		if content_size.x < control_size.x:
			content_size.x = control_size.x

		content_size.y += control_size.y
		if first:
			first = false
		else:
			content_size.y += content_separation

	if content_panel:
		content_size += content_panel.get_minimum_size()

	content_size.y *= _percent_revealed

	# Combine the two.
	var final_size := title_size
	if final_size.x < content_size.x:
		final_size.x = content_size.x
	final_size.y += content_size.y

	return final_size


func _resort() -> void:
	var content_offset := 0
	var base_width := size.x

	if is_instance_valid(_toggle_bar):
		var bar_position := Vector2.ZERO
		var bar_size := _toggle_bar.custom_minimum_size
		bar_size.x = base_width

		if _title_style:
			bar_position.x += _title_style.get_margin(SIDE_LEFT)
			bar_position.y += _title_style.get_margin(SIDE_TOP)
			bar_size.x -= _title_style.get_margin(SIDE_LEFT) + _title_style.get_margin(SIDE_RIGHT)

		fit_child_in_rect(_toggle_bar, Rect2(bar_position, bar_size))
		_update_icon_anchor()

		content_offset = int(_toggle_bar.size.y)
		if _title_style:
			content_offset += int(_title_style.get_margin(SIDE_TOP) + _title_style.get_margin(SIDE_BOTTOM))

	var first := true
	for child_node in get_children():
		var control_node := child_node as Control
		if not control_node or not control_node.is_visible_in_tree():
			continue
		if control_node == _toggle_bar:
			continue

		var position := Vector2.ZERO
		var size := control_node.custom_minimum_size
		size.x = base_width

		if content_panel:
			position.x += content_panel.get_margin(SIDE_LEFT)
			size.x -= content_panel.get_margin(SIDE_LEFT) + content_panel.get_margin(SIDE_RIGHT)

		if first:
			first = false
			if content_panel:
				content_offset += int(content_panel.get_margin(SIDE_TOP))
		else:
			content_offset += content_separation
		position.y = content_offset

		fit_child_in_rect(control_node, Rect2(position, size))
		content_offset += int(control_node.size.y)


func set_title(value: String) -> void:
	title = value
	if is_inside_tree():
		_toggle_label.text = title


func set_is_expanded(value: bool) -> void:
	if is_expanded == value:
		return

	is_expanded = value
	if is_expanded:
		emit_signal("expanded")

	if is_inside_tree():
		_toggle_button.button_pressed = is_expanded
		_toggle_content(is_expanded)


func set_title_font_color(value: Color) -> void:
	title_font_color = value
	_update_theme()


func set_title_icon_color(value: Color) -> void:
	title_icon_color = value
	_update_theme()


func set_title_font(value: Font) -> void:
	title_font = value
	_update_theme()
	update_minimum_size()
	notification(NOTIFICATION_THEME_CHANGED)


func set_title_panel(value: StyleBox) -> void:
	if title_panel == value:
		return

	if title_panel:
		title_panel.changed.disconnect(update_minimum_size)
		title_panel.changed.disconnect(queue_sort)
		title_panel.changed.disconnect(queue_redraw)

	title_panel = value
	if title_panel and not title_panel.changed.is_connected(update_minimum_size):
		title_panel.changed.connect(update_minimum_size)
		title_panel.changed.connect(queue_sort)
		title_panel.changed.connect(queue_redraw)

	update_minimum_size()
	notification(NOTIFICATION_THEME_CHANGED)


func set_title_panel_expanded(value: StyleBox) -> void:
	if title_panel_expanded == value:
		return

	if title_panel_expanded:
		title_panel_expanded.changed.disconnect(update_minimum_size)
		title_panel_expanded.changed.disconnect(queue_sort)
		title_panel_expanded.changed.disconnect(queue_redraw)

	title_panel_expanded = value
	if title_panel_expanded and not title_panel_expanded.changed.is_connected(update_minimum_size):
		title_panel_expanded.changed.connect(update_minimum_size)
		title_panel_expanded.changed.connect(queue_sort)
		title_panel_expanded.changed.connect(queue_redraw)

	update_minimum_size()
	notification(NOTIFICATION_THEME_CHANGED)


func get_title_panel_style() -> StyleBox:
	if _percent_revealed > 0.0 and title_panel_expanded:
		return title_panel_expanded
	return title_panel


func set_content_panel(value: StyleBox) -> void:
	if content_panel == value:
		return

	if content_panel:
		content_panel.changed.disconnect(update_minimum_size)
		content_panel.changed.disconnect(queue_sort)
		content_panel.changed.disconnect(queue_redraw)

	content_panel = value
	if content_panel and not content_panel.changed.is_connected(update_minimum_size):
		content_panel.changed.connect(update_minimum_size)
		content_panel.changed.connect(queue_sort)
		content_panel.changed.connect(queue_redraw)

	update_minimum_size()
	notification(NOTIFICATION_THEME_CHANGED)


func set_content_separation(value: int) -> void:
	content_separation = value
	update_minimum_size()
	notification(NOTIFICATION_THEME_CHANGED)


func get_contents() -> Array:
	return _content_children


func _toggle_content(expanded: bool, immediate: bool = false) -> void:
	# Just change immediately.
	if immediate:
		for child_node in get_children():
			var control_node := child_node as Control
			if not control_node or control_node == _toggle_bar:
				continue

			control_node.visible = expanded

		_toggle_icon.rotation = 90.0 * int(expanded)
		_percent_revealed = 1.0 * int(expanded)
		return

	# Animate the change smoothly.

	for child_node in get_children():
		var control_node := child_node as Control
		if not control_node or control_node == _toggle_bar:
			continue

		if expanded:
			control_node.visible = true

	if _scene_tween:
		_scene_tween.kill()
	_scene_tween = create_tween().set_parallel()
	_scene_tween.finished.connect(_on_tween_completed)
	_scene_tween.tween_property(_toggle_icon, "rotation_degrees", 90.0 * int(expanded), ANIMATION_ICON_DURATION).from(_toggle_icon.rotation).set_trans(Tween.TRANS_QUAD)

	var final_value := 1.0 * int(expanded)
	_scene_tween.tween_property(self, "_percent_revealed", final_value, ANIMATION_REVEAL_DURATION).from(1.0 - final_value).set_trans(Tween.TRANS_QUAD)
	_scene_tween.tween_method(_on_tween_step, 0, 1.0, ANIMATION_REVEAL_DURATION)


func _on_toggle_entered() -> void:
	_toggle_bar.modulate.a = TOGGLE_OPACITY_HOVER


func _on_toggle_exited() -> void:
	_toggle_bar.modulate.a = TOGGLE_OPACITY


func _on_toggle_pressed(pressed: bool) -> void:
	set_is_expanded(pressed)


func _on_tween_step(_step: float) -> void:
	_title_style = get_title_panel_style()
	update_minimum_size()


func _on_tween_completed() -> void:
	_title_style = get_title_panel_style()
	queue_redraw()

	if not is_expanded:
		for child_node in get_children():
			var control_node := child_node as Control
			if not control_node or control_node == _toggle_bar:
				continue

			control_node.visible = false
