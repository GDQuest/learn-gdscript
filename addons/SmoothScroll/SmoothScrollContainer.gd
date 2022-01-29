# Adds smooth scrolling support to vertical ScrollContainer nodes.
#
# This works by moving a direct child of the container. See `_content`.
class_name SmoothScrollContainer
extends ScrollContainer

# Amount of pixels to offset the scroll target when scrolling with the mouse
# wheel or the touchpad.
const MOUSE_SCROLL_STEP := 80.0
# When the velocity's squared length gets below this value, we set it to zero.
const ARRIVE_THRESHOLD := 1.0
const ARRIVE_DISTANCE_BASE := 200.0
const ARRIVE_DISTANCE_FAST := 1200.0
const SPEED_BASE := 4000.0
const SPEED_FAST := 16000.0

# Maximum scroll speed in pixels per second.
var max_speed := SPEED_BASE
var arrive_distance := ARRIVE_DISTANCE_BASE

# Current velocity of the content node.
var _velocity := Vector2(0, 0)
# Current scroll coordinated. We use this to track and force the scrollbars to
# specific scrolling as directly updating the scroll properties conflicts with
# the ScrollContainer's native behavior.
var _current_scroll := Vector2.ZERO
var _target_position := Vector2.ZERO setget _set_target_position
var _max_position_y := 0.0

# Control node to move when scrolling.
onready var _content: Control = get_child(get_child_count() - 1) as Control
onready var _scroll_sensitivity := 1.0


func _ready() -> void:
	set_process(false)

	_update_max_position_y()
	_content.connect("resized", self, "_update_max_position_y")

	get_v_scrollbar().connect("scrolling", self, "_on_VScrollBar_scrolling")

	var user_profile := UserProfiles.get_profile()
	_scroll_sensitivity = user_profile.scroll_sensitivity
	user_profile.connect(
		"scroll_sensitivity_changed", self, "_on_UserProfile_scroll_sensitivity_changed"
	)


func _process(delta: float) -> void:
	var distance_to_target = _current_scroll.distance_to(_target_position)
	if distance_to_target <= ARRIVE_THRESHOLD * max_speed / SPEED_BASE:
		set_process(false)
		max_speed = SPEED_BASE
		arrive_distance = ARRIVE_DISTANCE_BASE
		return

	var direction := _current_scroll.direction_to(_target_position)
	var desired_velocity := direction * max_speed
	if distance_to_target < arrive_distance:
		desired_velocity *= distance_to_target / arrive_distance

	var steering := desired_velocity - _velocity
	_velocity += steering / 2.0

	_current_scroll += _velocity * delta
	scroll_vertical = _current_scroll.y


func _gui_input(event: InputEvent) -> void:
	if event.is_action("scroll_up") and event.pressed:
		scroll_up()
	elif event.is_action("scroll_down") and event.pressed:
		scroll_down()
	elif event.is_action_pressed("scroll_up_one_page"):
		scroll_page_up()
	elif event.is_action_pressed("scroll_down_one_page"):
		scroll_page_down()
	elif event.is_action_pressed("scroll_to_top"):
		scroll_to_top()
	elif event.is_action_pressed("scroll_to_bottom"):
		scroll_to_bottom()


func scroll_up() -> void:
	_set_target_position(_target_position + Vector2.UP * MOUSE_SCROLL_STEP * _scroll_sensitivity)


func scroll_down() -> void:
	_set_target_position(_target_position + Vector2.DOWN * MOUSE_SCROLL_STEP * _scroll_sensitivity)


func scroll_page_up() -> void:
	_set_target_position(_target_position + Vector2.UP * rect_size.y)


func scroll_page_down() -> void:
	_set_target_position(_target_position + Vector2.DOWN * rect_size.y)


func scroll_to_top() -> void:
	_set_target_position(Vector2.ZERO)
	max_speed = SPEED_FAST
	arrive_distance = ARRIVE_DISTANCE_FAST


func scroll_to_bottom() -> void:
	_set_target_position(Vector2.DOWN * _max_position_y)
	max_speed = SPEED_FAST
	arrive_distance = ARRIVE_DISTANCE_FAST


func _set_target_position(new_position: Vector2) -> void:
	_target_position = new_position
	_target_position.y = clamp(_target_position.y, 0.0, _max_position_y)
	set_process(true)


func _update_max_position_y() -> void:
	_max_position_y = _content.rect_size.y - rect_size.y


func _on_VScrollBar_scrolling() -> void:
	if is_processing():
		set_process(false)
	_current_scroll.y = scroll_vertical
	_target_position.y = scroll_vertical


func _on_UserProfile_scroll_sensitivity_changed(new_value: float) -> void:
	_scroll_sensitivity = new_value
