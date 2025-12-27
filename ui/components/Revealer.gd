@tool
@icon("./Revealer.svg")
class_name Revealer
extends Container

const ANIMATION_ICON_DURATION := 0.10
const ANIMATION_REVEAL_DURATION := 0.24

const TOGGLE_OPACITY := 0.65
const TOGGLE_OPACITY_HOVER := 1.0

signal expanded

@export var title: String = "Expand":
	set(value):
		set_title(value)

@export var is_expanded: bool = false:
	set(value):
		set_is_expanded(value)

@export var title_font_color: Color = Color.WHITE:
	set(value):
		set_title_font_color(value)

@export var title_icon_color: Color = Color.WHITE:
	set(value):
		set_title_icon_color(value)

@export var title_font: Font:
	set(value):
		set_title_font(value)

@export var title_panel: StyleBox:
	set(value):
		set_title_panel(value)

@export var title_panel_expanded: StyleBox:
	set(value):
		set_title_panel_expanded(value)

@export var content_panel: StyleBox:
	set(value):
		set_content_panel(value)

@export var content_separation: int = 2:
	set(value):
		set_content_separation(value)

@onready var _toggle_bar := $ToggleBar as PanelContainer
@onready var _toggle_button := $ToggleBar/ToggleCapturer as Button
@onready var _toggle_label := $ToggleBar/BarLayout/Label as Label
@onready var _toggle_icon_anchor := $ToggleBar/BarLayout/ToggleIcon as Control
@onready var _toggle_icon := $ToggleBar/BarLayout/ToggleIcon/Texture as TextureRect

var _content_children: Array[Control] = []
var _percent_revealed: float = 0.0
var _title_style: StyleBox

var _tween: Tween


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_toggle_label.text = title
	_toggle_button.button_pressed = is_expanded

	_index_content()
	_update_icon_anchor()
	_update_theme()

	_toggle_bar.modulate.a = TOGGLE_OPACITY

	_toggle_button.mouse_entered.connect(_on_toggle_entered)
	_toggle_button.mouse_exited.connect(_on_toggle_exited)

	# ToggleCapturer should be in toggle mode in the scene. If it isn't, "toggled" won't fire.
	# In that case, you can swap to: _toggle_button.pressed.connect(func(): _on_toggle_pressed(_toggle_button.button_pressed))
	_toggle_button.toggled.connect(_on_toggle_pressed)

	# Keep content list in sync without overriding add_child/remove_child.
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)

	_toggle_content(is_expanded, true)
	_title_style = get_title_panel_style()


func _draw() -> void:
	var title_size: Vector2 = _toggle_bar.size

	if _title_style:
		var title_rect := Rect2(Vector2.ZERO, Vector2(size.x, _toggle_bar.size.y + _title_style.get_minimum_size().y))
		draw_style_box(_title_style, title_rect)
		title_size += _title_style.get_minimum_size()

	if content_panel:
		var content_rect := Rect2(Vector2(0.0, title_size.y), Vector2(size.x, size.y - title_size.y))
		draw_style_box(content_panel, content_rect)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_resort()


func _on_child_entered_tree(node: Node) -> void:
	var c := node as Control
	if c == null:
		return
	if c == _toggle_bar:
		return
	if _content_children.has(c):
		return
	_content_children.append(c)
	queue_sort()
	update_minimum_size()


func _on_child_exiting_tree(node: Node) -> void:
	var c := node as Control
	if c == null:
		return
	if _content_children.has(c):
		_content_children.erase(c)
	queue_sort()
	update_minimum_size()


func _index_content() -> void:
	_content_children.clear()
	for child_node in get_children():
		var control_node := child_node as Control
		if control_node == null:
			continue
		if control_node == _toggle_bar:
			continue
		_content_children.append(control_node)


func _update_icon_anchor() -> void:
	if not is_inside_tree():
		return

	_toggle_icon_anchor.custom_minimum_size = _toggle_icon.size
	_toggle_icon.pivot_offset = _toggle_icon.size / 2.0


func _update_theme() -> void:
	if not is_inside_tree():
		return

	if title_font:
		_toggle_label.add_theme_font_override("font", title_font)
	_toggle_label.add_theme_color_override("font_color", title_font_color)

	_toggle_icon.modulate = title_icon_color


func _get_minimum_size() -> Vector2:
	var title_size := Vector2.ZERO
	if is_instance_valid(_toggle_bar):
		title_size = _toggle_bar.get_combined_minimum_size()

	if _title_style:
		title_size += _title_style.get_minimum_size()

	var content_size := Vector2.ZERO
	var first := true

	for child_node in get_children():
		var control_node := child_node as Control
		if control_node == null:
			continue
		if control_node == _toggle_bar:
			continue
		if not control_node.is_visible_in_tree():
			continue

		var control_size := control_node.get_combined_minimum_size()
		content_size.x = max(content_size.x, control_size.x)

		content_size.y += control_size.y
		if first:
			first = false
		else:
			content_size.y += float(content_separation)

	if content_panel:
		content_size += content_panel.get_minimum_size()

	content_size.y *= _percent_revealed

	var final_size := title_size
	final_size.x = max(final_size.x, content_size.x)
	final_size.y += content_size.y
	return final_size


func _resort() -> void:
	var content_offset := 0.0
	var base_width: float = size.x

	if is_instance_valid(_toggle_bar):
		var bar_position := Vector2.ZERO
		var bar_size := _toggle_bar.custom_minimum_size
		bar_size.x = base_width

		if _title_style:
			bar_position.x += _title_style.get_margin(Side.SIDE_LEFT)
			bar_position.y += _title_style.get_margin(Side.SIDE_TOP)
			bar_size.x -= _title_style.get_margin(Side.SIDE_LEFT) + _title_style.get_margin(Side.SIDE_RIGHT)

		fit_child_in_rect(_toggle_bar, Rect2(bar_position, bar_size))
		_update_icon_anchor()

		content_offset = _toggle_bar.size.y
		if _title_style:
			content_offset += _title_style.get_margin(Side.SIDE_TOP) + _title_style.get_margin(Side.SIDE_BOTTOM)

	var first := true
	for child_node in get_children():
		var control_node := child_node as Control
		if control_node == null:
			continue
		if control_node == _toggle_bar:
			continue
		if not control_node.is_visible_in_tree():
			continue

		var pos := Vector2.ZERO
		var sz := control_node.custom_minimum_size
		sz.x = base_width

		if content_panel:
			pos.x += content_panel.get_margin(Side.SIDE_LEFT)
			sz.x -= content_panel.get_margin(Side.SIDE_LEFT) + content_panel.get_margin(Side.SIDE_RIGHT)

		if first:
			first = false
			if content_panel:
				content_offset += content_panel.get_margin(Side.SIDE_TOP)
		else:
			content_offset += float(content_separation)

		pos.y = content_offset
		fit_child_in_rect(control_node, Rect2(pos, sz))
		content_offset += control_node.size.y


func set_title(value: String) -> void:
	title = value
	if is_inside_tree():
		_toggle_label.text = title


func set_is_expanded(value: bool) -> void:
	if is_expanded == value:
		return

	is_expanded = value
	if is_expanded:
		expanded.emit()

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
	queue_sort()


func _disconnect_stylebox(sb: StyleBox) -> void:
	if sb == null:
		return
	if sb.changed.is_connected(_on_stylebox_changed):
		sb.changed.disconnect(_on_stylebox_changed)


func _connect_stylebox(sb: StyleBox) -> void:
	if sb == null:
		return
	if not sb.changed.is_connected(_on_stylebox_changed):
		sb.changed.connect(_on_stylebox_changed)


func _on_stylebox_changed() -> void:
	update_minimum_size()
	queue_sort()
	queue_redraw()


func set_title_panel(value: StyleBox) -> void:
	if title_panel == value:
		return
	_disconnect_stylebox(title_panel)
	title_panel = value
	_connect_stylebox(title_panel)
	update_minimum_size()
	queue_sort()


func set_title_panel_expanded(value: StyleBox) -> void:
	if title_panel_expanded == value:
		return
	_disconnect_stylebox(title_panel_expanded)
	title_panel_expanded = value
	_connect_stylebox(title_panel_expanded)
	update_minimum_size()
	queue_sort()


func get_title_panel_style() -> StyleBox:
	if _percent_revealed > 0.0 and title_panel_expanded:
		return title_panel_expanded
	return title_panel


func set_content_panel(value: StyleBox) -> void:
	if content_panel == value:
		return
	_disconnect_stylebox(content_panel)
	content_panel = value
	_connect_stylebox(content_panel)
	update_minimum_size()
	queue_sort()


func set_content_separation(value: int) -> void:
	content_separation = value
	update_minimum_size()
	queue_sort()


func get_contents() -> Array:
	return _content_children


func _toggle_content(open: bool, immediate: bool = false) -> void:
	if immediate:
		for child_node in get_children():
			var control_node := child_node as Control
			if control_node == null or control_node == _toggle_bar:
				continue
			control_node.visible = open

		_toggle_icon.rotation_degrees = 90.0 * float(int(open))
		_percent_revealed = float(int(open))
		_title_style = get_title_panel_style()
		update_minimum_size()
		queue_sort()
		queue_redraw()
		return

	if _tween and _tween.is_running():
		_tween.kill()

	for child_node in get_children():
		var control_node := child_node as Control
		if control_node == null or control_node == _toggle_bar:
			continue
		if open:
			control_node.visible = true

	var final_value := float(int(open))

	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	_tween.tween_property(_toggle_icon, "rotation_degrees", 90.0 * final_value, ANIMATION_ICON_DURATION)
	_tween.tween_property(self, "_percent_revealed", final_value, ANIMATION_REVEAL_DURATION)

	_tween.tween_callback(func() -> void:
		_title_style = get_title_panel_style()
		update_minimum_size()
		queue_sort()
		queue_redraw()

		if not is_expanded:
			for child_node in get_children():
				var control_node := child_node as Control
				if control_node == null or control_node == _toggle_bar:
					continue
				control_node.visible = false
	)

func _on_toggle_entered() -> void:
	_toggle_bar.modulate.a = TOGGLE_OPACITY_HOVER


func _on_toggle_exited() -> void:
	_toggle_bar.modulate.a = TOGGLE_OPACITY


func _on_toggle_pressed(pressed: bool) -> void:
	set_is_expanded(pressed)
