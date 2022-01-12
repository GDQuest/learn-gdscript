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
class_name SortableList
extends ScrollContainer

signal item_moved(item_index, new_index)
signal item_requested_at_index(new_index)

const DRAG_POSITION_SIZE := 8.0

const INSERT_AREA_SIZE := 24.0
const INSERT_AREA_WIDTH := 12.0
const INSERT_AREA_BULB := 12.0
const INSERT_AREA_TIME := 0.5

const INSERT_AREA_ICON := preload("res://addons/gdscript-course-builder/icons/insert-content-block.png")

export var drag_enabled := true
export var insert_enabled := false

var _drag_source_tag := ""
var _is_dragging := false
var _highlight_rect := Rect2(-1, -1, 0, 0)
var _highlight_on_top := false

var _insert_item_areas := []
var _possible_insert_area := -1
var _active_insert_area := -1
var _insert_area_timer := 0.0

onready var _item_list := $Items as VBoxContainer
onready var _overlay_layer := $Overlay as Control


func _ready() -> void:
	if _drag_source_tag.empty():
		_drag_source_tag = str(randi() % 100000 + 10000)

	_item_list.connect("minimum_size_changed", self, "_on_item_list_size_changed")
	connect("resized", self, "_on_item_list_size_changed")
	_overlay_layer.connect("draw", self, "_draw_overlay")
	
	_update_hot_areas()


func _process(delta: float) -> void:
	if _possible_insert_area >= 0:
		_insert_area_timer += delta
		
		if _insert_area_timer >= INSERT_AREA_TIME:
			_active_insert_area = _possible_insert_area
			_possible_insert_area = -1
			_insert_area_timer = 0.0
			_overlay_layer.update()
	
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


func _gui_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm:
		# Use mouse position to detect when we hover over the trigger area for inserting items.
		var mouse_position := mm.position + Vector2(0, scroll_vertical)
		# If there are no areas, clear any related state data.
		if _insert_item_areas.size() == 0:
			_active_insert_area = -1
			_possible_insert_area = -1
			_insert_area_timer = 0.0
			_overlay_layer.update()
			return
		
		# Iterate through the areas until we find one.
		var area_index := 0
		for insert_area in _insert_item_areas:
			# Not interested.
			if not insert_area.has_point(mouse_position):
				area_index += 1
				continue
			
			# It's already active, clear up the state data just in case and return.
			if _active_insert_area == area_index:
				_possible_insert_area = -1
				_insert_area_timer = 0.0
				return
			
			# It's already detected for hover, return.
			if _possible_insert_area == area_index:
				return
			
			# It's a new area that we hover over, start tracking it, hide the old area.
			_active_insert_area = -1
			_possible_insert_area = area_index
			_insert_area_timer = 0.0
			_overlay_layer.update()
			return
		
		# We reached here without triggering any area, clear all state data.
		_active_insert_area = -1
		_possible_insert_area = -1
		_insert_area_timer = 0.0
		_overlay_layer.update()
		return
	
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == BUTTON_LEFT and not mb.pressed:
		# Check if we clicked on the insert trigger area, if we even have one.
		if _active_insert_area >= 0 and _active_insert_area < _insert_item_areas.size():
			var target_area = _insert_item_areas[_active_insert_area]
			var mouse_position := mb.position + Vector2(0, scroll_vertical)
			
			if target_area.has_point(mouse_position):
				# Insert index follows the index of the area.
				emit_signal("item_requested_at_index", _active_insert_area + 1)
				_active_insert_area = -1
	


func _draw_overlay() -> void:
	# Draw insert highlight
	if _active_insert_area >= 0 and _active_insert_area < _insert_item_areas.size():
		var insert_rect = _insert_item_areas[_active_insert_area]
		var insert_area_color = get_color("accent_color", "Editor")
		
		var visible_insert_rect := Rect2()
		visible_insert_rect.position.x = insert_rect.position.x
		visible_insert_rect.position.y = insert_rect.position.y + insert_rect.size.y / 2 - INSERT_AREA_WIDTH / 2
		visible_insert_rect.size.x = insert_rect.size.x
		visible_insert_rect.size.y = INSERT_AREA_WIDTH
		_overlay_layer.draw_rect(visible_insert_rect, insert_area_color, true)
		
		var area_center = insert_rect.size / 2 + insert_rect.position
		var circle_points := PoolVector2Array()
		var circle_details := 24
		var circle_step := 2 * PI / circle_details
		for n in circle_details:
			circle_points.append(area_center + Vector2(0, INSERT_AREA_BULB).rotated(n * circle_step))
		_overlay_layer.draw_colored_polygon(circle_points, insert_area_color, PoolVector2Array(), null, null, true)
		
		_overlay_layer.draw_texture(INSERT_AREA_ICON, area_center - INSERT_AREA_ICON.get_size() / 2)
	
	# Draw drag'n'drop highlight
	if _highlight_rect.position.x != -1 and _highlight_rect.position.y != -1:
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


func _update_hot_areas() -> void:
	_insert_item_areas = []
	if not insert_enabled:
		return
	
	for i in _item_list.get_child_count() - 1:
		var child_node := _item_list.get_child(i) as Control
		
		var insert_rect := Rect2()
		insert_rect.position.x = child_node.rect_position.x
		insert_rect.position.y = child_node.rect_position.y + child_node.rect_size.y
		
		insert_rect.position.y -= INSERT_AREA_SIZE / 2
		insert_rect.size = Vector2(child_node.rect_size.x, INSERT_AREA_SIZE)
		
		_insert_item_areas.append(insert_rect)


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
	if not is_inside_tree():
		return
	
	yield(get_tree(), "idle_frame")
	_overlay_layer.rect_min_size = Vector2(0, _item_list.rect_size.y)
	_overlay_layer.rect_size = _overlay_layer.rect_min_size
	
	_update_hot_areas()
	_overlay_layer.update()
