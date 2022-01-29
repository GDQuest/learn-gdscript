# Adds smooth scrolling support to vertical ScrollContainer nodes.
#
# This works by moving a direct child of the container. See `_content`.
class_name SmoothScrollContainer
extends ScrollContainer

# When the velocity gets below this value, we set it to zero.
var STOP_VELOCITY_THRESHOLD := 0.01

# Controls the added speed when receiving one scroll event.
export(float, 10, 1) var speed := 2.0
# Controls the damping of movement when _dragging_scroll_bar past the container's limits.
export(float, 0, 1) var damping := 0.1

# Current velocity of the content node.
var _velocity := Vector2(0, 0)
# Current counterforce for "overdragging" on the top side.
var _over_drag_multiplicator_top := 1.0
# Current counterforce for "overdragging" on the bottom side.
var _over_drag_multiplicator_bottom := 1.0
# Current position of content node. We use this to track and force the child
# node's position as directly updating the node's position conflicts with the
# ScrollContainer's native behavior.
var _content_position := Vector2.ZERO
# If true, the content node's position is controled by dragging the scroll bar.
var _dragging_scroll_bar := false

# Control node to move when scrolling.
onready var _content: Control = get_child(get_child_count() - 1)
onready var _scroll_sensitivity := 1.0


func _ready() -> void:
	get_v_scrollbar().connect("scrolling", self, "_on_VScrollBar_scrolling")

	var user_profile := UserProfiles.get_profile()
	_scroll_sensitivity = user_profile.scroll_sensitivity
	user_profile.connect(
		"scroll_sensitivity_changed", self, "_on_UserProfile_scroll_sensitivity_changed"
	)


func _process(delta: float) -> void:
	# If no scroll needed, we skip calculations.
	if _content.rect_size.y - rect_size.y < 1.0:
		return
	elif _dragging_scroll_bar:
		_content_position = _content.rect_position
		return

	# Detecting scrolling past the top or bottom of the scroll area.
	var distance_to_bottom := _content.rect_position.y + _content.rect_size.y - rect_size.y
	if distance_to_bottom < 0.0:
		_over_drag_multiplicator_bottom = 1.0 / abs(distance_to_bottom) * 10.0
	else:
		_over_drag_multiplicator_bottom = 1.0

	var distance_to_top := _content.rect_position.y
	if distance_to_top > 0.0:
		_over_drag_multiplicator_top = 1.0 / abs(distance_to_top) * 10.0
	else:
		_over_drag_multiplicator_top = 1.0

	_velocity.y *= 0.9
	if abs(_velocity.y) <= STOP_VELOCITY_THRESHOLD:
		_velocity.y = 0.0

	# Applies counterforces when overdragging
	if distance_to_bottom < 0.0:
		_velocity.y = lerp(_velocity.y, -distance_to_bottom / 8.0, damping)
	if distance_to_top > 0.0:
		_velocity.y = lerp(_velocity.y, -distance_to_top / 8.0, damping)

	_content_position += _velocity * _scroll_sensitivity
	_content.rect_position = _content_position
	set_v_scroll(-_content_position.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed:
			_dragging_scroll_bar = false

		match event.button_index:
			BUTTON_WHEEL_DOWN:
				_velocity.y -= speed
			BUTTON_WHEEL_UP:
				_velocity.y += speed


func _on_VScrollBar_scrolling() -> void:
	_dragging_scroll_bar = true


# Scrolls up a page
func scroll_page_up() -> void:
	_velocity.y += rect_size.y / 10 / _scroll_sensitivity


# Scrolls down a page
func scroll_page_down() -> void:
	_velocity.y -= rect_size.y / 10 / _scroll_sensitivity


# Adds _velocity to the vertical scroll
func scroll_vertical(amount: float) -> void:
	_velocity.y -= amount


func scroll_to_top() -> void:
	_velocity.y = 0.0
	_content_position.y = 0.0
	_content.rect_position = _content_position
	set_v_scroll(-_content_position.y)


func scroll_to_bottom() -> void:
	_velocity.y = 0.0
	_content_position.y = -_content.rect_size.y + rect_size.y
	_content.rect_position = _content_position
	set_v_scroll(-_content_position.y)


func _on_UserProfile_scroll_sensitivity_changed(new_value: float) -> void:
	_scroll_sensitivity = new_value
