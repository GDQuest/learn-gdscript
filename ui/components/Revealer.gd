tool
class_name Revealer, "./Revealer.svg"
extends Container

const ANIMATION_ICON_DURATION := 0.1
const ANIMATION_REVEAL_DURATION := 0.24

const TOGGLE_OPACITY := 0.65
const TOGGLE_OPACITY_HOVER := 1.0

signal expanded

export var title := "Expand" setget set_title
export var is_expanded := false setget set_is_expanded

export var title_font_color: Color = Color.white setget set_title_font_color
export var title_icon_color: Color = Color.white setget set_title_icon_color
export var title_font: Font setget set_title_font
export var title_panel: StyleBox setget set_title_panel
export var title_panel_expanded: StyleBox setget set_title_panel_expanded

export var content_panel: StyleBox setget set_content_panel
export var content_separation: int = 2 setget set_content_separation

onready var _tweener := $Tween as Tween
onready var _toggle_bar := $ToggleBar as PanelContainer
onready var _toggle_button := $ToggleBar/ToggleCapturer as Button
onready var _toggle_label := $ToggleBar/BarLayout/Label as Label
onready var _toggle_icon_anchor := $ToggleBar/BarLayout/ToggleIcon as Control
onready var _toggle_icon := $ToggleBar/BarLayout/ToggleIcon/Texture as TextureRect

var _content_children := []
var _percent_revealed := 0.0
var _title_style: StyleBox


func _ready() -> void:
	_toggle_label.text = title
	_toggle_button.pressed = is_expanded
	_index_content()
	_update_icon_anchor()
	_update_theme()

	_toggle_bar.modulate.a = TOGGLE_OPACITY

	_toggle_button.connect("mouse_entered", self, "_on_toggle_entered")
	_toggle_button.connect("mouse_exited", self, "_on_toggle_exited")
	_toggle_button.connect("toggled", self, "_on_toggle_pressed")
	_tweener.connect("tween_step", self, "_on_tweener_step")
	_tweener.connect("tween_all_completed", self, "_on_tweener_completed")

	_toggle_content(is_expanded, true)
	_title_style = get_title_panel_style()


func _draw() -> void:
	var title_size := _toggle_bar.rect_size

	if _title_style:
		var title_rect := Rect2()
		title_rect.position = Vector2(0, 0)
		title_rect.size = _toggle_bar.rect_size + _title_style.get_minimum_size()
		draw_style_box(_title_style, title_rect)

		title_size += _title_style.get_minimum_size()

	if content_panel:
		var content_rect := Rect2()
		content_rect.position = Vector2(0, title_size.y)
		content_rect.size = Vector2(rect_size.x, rect_size.y - title_size.y)
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

	_toggle_icon_anchor.rect_min_size = _toggle_icon.rect_size
	_toggle_icon.rect_pivot_offset = _toggle_icon.rect_size / 2


func _update_theme() -> void:
	if not is_inside_tree():
		return

	_toggle_label.add_font_override("font", title_font)
	_toggle_label.add_color_override("font_color", title_font_color)
	_toggle_icon.modulate = title_icon_color


func add_child(child_node: Node, legible_unique_name: bool = false) -> void:
	.add_child(child_node, legible_unique_name)

	var control_node := child_node as Control
	if not control_node or control_node == _toggle_bar:
		return

	_content_children.append(control_node)


func remove_child(child_node: Node) -> void:
	if _content_children.has(child_node):
		_content_children.erase(child_node)

	.remove_child(child_node)


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
	var base_width := rect_size.x

	if is_instance_valid(_toggle_bar):
		var bar_position := Vector2.ZERO
		var bar_size := _toggle_bar.rect_min_size
		bar_size.x = base_width

		if _title_style:
			bar_position.x += _title_style.get_margin(MARGIN_LEFT)
			bar_position.y += _title_style.get_margin(MARGIN_TOP)
			bar_size.x -= _title_style.get_margin(MARGIN_LEFT) + _title_style.get_margin(MARGIN_RIGHT)

		fit_child_in_rect(_toggle_bar, Rect2(bar_position, bar_size))
		_update_icon_anchor()

		content_offset = int(_toggle_bar.rect_size.y)
		if _title_style:
			content_offset += int(_title_style.get_margin(MARGIN_TOP) + _title_style.get_margin(MARGIN_BOTTOM))

	var first := true
	for child_node in get_children():
		var control_node := child_node as Control
		if not control_node or not control_node.is_visible_in_tree():
			continue
		if control_node == _toggle_bar:
			continue

		var position := Vector2.ZERO
		var size := control_node.rect_min_size
		size.x = base_width

		if content_panel:
			position.x += content_panel.get_margin(MARGIN_LEFT)
			size.x -= content_panel.get_margin(MARGIN_LEFT) + content_panel.get_margin(MARGIN_RIGHT)

		if first:
			first = false
			if content_panel:
				content_offset += int(content_panel.get_margin(MARGIN_TOP))
		else:
			content_offset += content_separation
		position.y = content_offset

		fit_child_in_rect(control_node, Rect2(position, size))
		content_offset += int(control_node.rect_size.y)


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
		_toggle_button.pressed = is_expanded
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
	minimum_size_changed()
	notification(NOTIFICATION_THEME_CHANGED)


func set_title_panel(value: StyleBox) -> void:
	if title_panel == value:
		return

	if title_panel:
		title_panel.disconnect("changed", self, "minimum_size_changed")
		title_panel.disconnect("changed", self, "queue_sort")
		title_panel.disconnect("changed", self, "update")

	title_panel = value
	if title_panel and not title_panel.is_connected("changed", self, "minimum_size_changed"):
		title_panel.connect("changed", self, "minimum_size_changed")
		title_panel.connect("changed", self, "queue_sort")
		title_panel.connect("changed", self, "update")

	minimum_size_changed()
	notification(NOTIFICATION_THEME_CHANGED)


func set_title_panel_expanded(value: StyleBox) -> void:
	if title_panel_expanded == value:
		return

	if title_panel_expanded:
		title_panel_expanded.disconnect("changed", self, "minimum_size_changed")
		title_panel_expanded.disconnect("changed", self, "queue_sort")
		title_panel_expanded.disconnect("changed", self, "update")

	title_panel_expanded = value
	if title_panel_expanded and not title_panel_expanded.is_connected("changed", self, "minimum_size_changed"):
		title_panel_expanded.connect("changed", self, "minimum_size_changed")
		title_panel_expanded.connect("changed", self, "queue_sort")
		title_panel_expanded.connect("changed", self, "update")

	minimum_size_changed()
	notification(NOTIFICATION_THEME_CHANGED)


func get_title_panel_style() -> StyleBox:
	if _percent_revealed > 0.0 and title_panel_expanded:
		return title_panel_expanded
	return title_panel


func set_content_panel(value: StyleBox) -> void:
	if content_panel == value:
		return

	if content_panel:
		content_panel.disconnect("changed", self, "minimum_size_changed")
		content_panel.disconnect("changed", self, "queue_sort")
		content_panel.disconnect("changed", self, "update")

	content_panel = value
	if content_panel and not content_panel.is_connected("changed", self, "minimum_size_changed"):
		content_panel.connect("changed", self, "minimum_size_changed")
		content_panel.connect("changed", self, "queue_sort")
		content_panel.connect("changed", self, "update")

	minimum_size_changed()
	notification(NOTIFICATION_THEME_CHANGED)


func set_content_separation(value: int) -> void:
	content_separation = value
	minimum_size_changed()
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

		_toggle_icon.rect_rotation = 90.0 * int(expanded)
		_percent_revealed = 1.0 * int(expanded)
		return

	# Animate the change smoothly.
	_tweener.stop_all()

	for child_node in get_children():
		var control_node := child_node as Control
		if not control_node or control_node == _toggle_bar:
			continue

		if expanded:
			control_node.visible = true

	_tweener.interpolate_property(
		_toggle_icon, "rect_rotation",
		_toggle_icon.rect_rotation, 90.0 * int(expanded),
		ANIMATION_ICON_DURATION, Tween.TRANS_QUAD, Tween.EASE_IN_OUT
	)

	var final_value := 1.0 * int(expanded)
	_tweener.interpolate_property(
		self, "_percent_revealed",
		1.0 - final_value, final_value,
		ANIMATION_REVEAL_DURATION, Tween.TRANS_QUAD, Tween.EASE_IN_OUT
	)
	_tweener.start()


func _on_toggle_entered() -> void:
	_toggle_bar.modulate.a = TOGGLE_OPACITY_HOVER


func _on_toggle_exited() -> void:
	_toggle_bar.modulate.a = TOGGLE_OPACITY


func _on_toggle_pressed(pressed: bool) -> void:
	set_is_expanded(pressed)


func _on_tweener_step(_object: Object, _key: NodePath, _elapsed: float, _value: Object) -> void:
	_title_style = get_title_panel_style()
	minimum_size_changed()


func _on_tweener_completed() -> void:
	_title_style = get_title_panel_style()
	update()

	if not is_expanded:
		for child_node in get_children():
			var control_node := child_node as Control
			if not control_node or control_node == _toggle_bar:
				continue

			control_node.visible = false
