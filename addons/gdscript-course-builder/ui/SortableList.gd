# A special container type to be used when a custom control needs to be displayed in a list,
# and that list must be resortable with drag'n'drop.
# It can work out of the box with any control children, but it's better to implement the following
# methods on child nodes:
#
#  get_drag_target_rect() - Returns the area that allows to start the drag, in child's coordinates.
#  get_drag_preview()     - Returns a custom Control node for the drag preview.
#  get_drop_target_rect() - Returns the area that serves as a drop zone, in child's coordinates.
#  enable_drop_target()   - Called to allow children handle being a drop target (stop events, etc).
#  disable_drop_target()  - Called to disable whatever logic was set up with the previous method.
#
# When using SortableList itself the following methods are available:
#
#  add_item()
#  clear_items()
#  get_item_count()
#  get_item()
#  set_drag_source_tag() - Useful to set a custom tag for drag payload, random sequence is used otherwise.

tool
extends ScrollContainer

signal item_moved(item_index, new_index)

const DRAG_POSITION_SIZE := 8.0

export var drag_enabled := true

var _drag_source_tag := ""
var _is_dragging := false
var _highlight_rect := Rect2(-1, -1, 0, 0)
var _highlight_on_top := false

onready var _item_list := $Items as VBoxContainer
onready var _overlay_layer := $Overlay as Control


func _ready() -> void:
	if _drag_source_tag.empty():
		_drag_source_tag = str(randi() % 100000 + 10000)

	_item_list.connect("minimum_size_changed", self, "_on_item_list_size_changed")
	_overlay_layer.connect("draw", self, "_draw_overlay")


func _process(delta: float) -> void:
	# Remove any residual state that we might have from previous drag attempts.
	if get_viewport().gui_is_dragging() or not _is_dragging:
		return

	if not _highlight_rect.position.x == -1 or not _highlight_rect.position.y == -1:
		_highlight_rect = Rect2(-1, -1, 0, 0)
		_overlay_layer.update()

	for child_node in _item_list.get_children():
		if child_node.has_method("disable_drop_target"):
			child_node.call("disable_drop_target")

	_is_dragging = false


func _draw_overlay() -> void:
	if _highlight_rect.position.x == -1 or _highlight_rect.position.y == -1:
		return

	var highlight_color = get_color("accent_color", "Editor")
	highlight_color.a = 0.125
	_overlay_layer.draw_rect(_highlight_rect, highlight_color, true)

	var visual_position_rect = Rect2()
	visual_position_rect.size = Vector2(_highlight_rect.size.x, DRAG_POSITION_SIZE)
	if _highlight_on_top:
		visual_position_rect.position = Vector2(
			_highlight_rect.position.x, _highlight_rect.position.y - DRAG_POSITION_SIZE / 2
		)
	else:
		visual_position_rect.position = Vector2(
			_highlight_rect.position.x, _highlight_rect.end.y - DRAG_POSITION_SIZE / 2
		)

	var highlight_border_color = get_color("accent_color", "Editor")
	_overlay_layer.draw_rect(visual_position_rect, highlight_border_color, true)


func get_drag_data(position: Vector2):
	if not drag_enabled:
		return null

	var item_index := 0
	for child_node in _item_list.get_children():
		var drag_rect: Rect2
		if child_node.has_method("get_drag_target_rect"):
			drag_rect = child_node.call("get_drag_target_rect")
			drag_rect.position += child_node.rect_global_position
		else:
			drag_rect = child_node.get_global_rect()

		drag_rect.position -= rect_global_position

		if drag_rect.has_point(position):
			if child_node.has_method("get_drag_preview"):
				set_drag_preview(child_node.call("get_drag_preview"))
			else:
				var drag_preview := Label.new()
				drag_preview.text = "List item #%d" % [item_index + 1]
				set_drag_preview(drag_preview)

			var drag_data := {}
			drag_data.source = _drag_source_tag
			drag_data.item_index = item_index
			return drag_data

		item_index += 1

	return null


func can_drop_data(position: Vector2, drag_data) -> bool:
	if not drag_enabled:
		return false

	_is_dragging = true
	_highlight_rect = Rect2(-1, -1, 0, 0)

	if typeof(drag_data) != TYPE_DICTIONARY:
		_overlay_layer.update()
		return false
	if not drag_data.has("source") or not drag_data.source == _drag_source_tag:
		_overlay_layer.update()
		return false

	var item_index := 0
	for child_node in _item_list.get_children():
		var drop_rect: Rect2
		if child_node.has_method("get_drop_target_rect"):
			drop_rect = child_node.call("get_drop_target_rect")
			drop_rect.position += child_node.rect_global_position
		else:
			drop_rect = child_node.get_global_rect()

		drop_rect.position -= rect_global_position

		if drop_rect.has_point(position):
			if item_index == drag_data.item_index:
				_overlay_layer.update()
				return false

			if child_node.has_method("enable_drop_target"):
				child_node.call("enable_drop_target")

			var middle_point = drop_rect.position.y + drop_rect.size.y / 2
			# Corresponding halves of the target item would put the dragged item to its current place,
			# so we can ignore that.
			if position.y > middle_point and item_index == drag_data.item_index - 1:
				_overlay_layer.update()
				return false
			if position.y <= middle_point and item_index == drag_data.item_index + 1:
				_overlay_layer.update()
				return false

			if position.y > middle_point:
				_highlight_rect = Rect2(
					drop_rect.position + Vector2(0, drop_rect.size.y / 2),
					Vector2(drop_rect.size.x, drop_rect.size.y / 2)
				)
				_highlight_on_top = false
			else:
				_highlight_rect = Rect2(
					drop_rect.position, Vector2(drop_rect.size.x, drop_rect.size.y / 2)
				)
				_highlight_on_top = true

			_highlight_rect.position.y += scroll_vertical
			_overlay_layer.update()
			return true

		item_index += 1

	_overlay_layer.update()
	return false


func drop_data(position: Vector2, drag_data) -> void:
	if not drag_enabled:
		return

	_highlight_rect = Rect2(-1, -1, 0, 0)

	if typeof(drag_data) != TYPE_DICTIONARY:
		_overlay_layer.update()
		return
	if not drag_data.has("source") or not drag_data.source == _drag_source_tag:
		_overlay_layer.update()
		return

	var item_index := 0
	for child_node in _item_list.get_children():
		var drop_rect: Rect2
		if child_node.has_method("get_drop_target_rect"):
			drop_rect = child_node.call("get_drop_target_rect")
			drop_rect.position += child_node.rect_global_position
		else:
			drop_rect = child_node.get_global_rect()

		drop_rect.position -= rect_global_position

		if drop_rect.has_point(position):
			if item_index == drag_data.item_index:
				_overlay_layer.update()
				return

			var middle_point = drop_rect.position.y + drop_rect.size.y / 2
			# Corresponding halves of the target item would put the dragged item to its current place,
			# so we can ignore that.
			if position.y > middle_point and item_index == drag_data.item_index - 1:
				_overlay_layer.update()
				return
			if position.y <= middle_point and item_index == drag_data.item_index + 1:
				_overlay_layer.update()
				return

			if position.y > middle_point:
				emit_signal("item_moved", drag_data.item_index, item_index + 1)
			else:
				emit_signal("item_moved", drag_data.item_index, item_index)

			_overlay_layer.update()
			return

		item_index += 1

	_overlay_layer.update()
	return


func set_drag_source_tag(source: String) -> void:
	_drag_source_tag = source


func clear_items() -> void:
	for child_node in _item_list.get_children():
		_item_list.remove_child(child_node)
		child_node.queue_free()


func add_item(control: Control) -> void:
	_item_list.add_child(control)


func get_item_count() -> int:
	return _item_list.get_child_count()


func get_item(item_index: int) -> Control:
	if item_index < 0 or item_index >= _item_list.get_child_count():
		return null

	return _item_list.get_child(item_index) as Control


# Handlers
func _on_item_list_size_changed() -> void:
	yield(get_tree(), "idle_frame")
	_overlay_layer.rect_min_size = Vector2(0, _item_list.rect_size.y)
	_overlay_layer.rect_size = _overlay_layer.rect_min_size
	_overlay_layer.update()
