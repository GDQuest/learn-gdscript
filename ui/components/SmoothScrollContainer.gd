# Adds smooth scrolling support to vertical ScrollContainer nodes.
#
# This works by moving a direct child of the container. See `_content`.
@icon("smooth_scroll_container_icon.svg")
class_name SmoothScrollContainer
extends ScrollContainer

# Amount of pixels to offset the scroll target when scrolling with the mouse
# wheel or the touchpad.
const MOUSE_SCROLL_STEP := 80.0
# When the velocity's squared length gets below this value, we set it to zero.
const ARRIVE_THRESHOLD := 1.0
const ARRIVE_DISTANCE_BASE := 200.0

# Base scroll speed in pixels per second.
const SPEED_BASE := 3000.0
# If the target scroll is farther than this distance, we increase the scrolling
# speed proportionally.
const ACCELERATE_DISTANCE_THRESHOLD := 240.0
# Used to multiply the scroll speed as the target scroll gets farther away than
# ACCELERATE_DISTANCE_THRESHOLD.
const SPEED_DISTANCE_DIVISOR := 200.0
const TIME_MSEC_BETWEEN_SCROLL_EVENTS := 15

# Scroll speed in pixels per second.
var scroll_speed := SPEED_BASE
var arrive_distance := ARRIVE_DISTANCE_BASE

# Current velocity of the content node.
var _velocity := Vector2(0, 0)
# Current scroll coordinated. We use this to track and force the scrollbars to
# specific scrolling as directly updating the scroll properties conflicts with
# the ScrollContainer's native behavior.
var _current_scroll := Vector2.ZERO
var _target_position := Vector2.ZERO: set = _set_target_position
var _max_position_y := 0.0

# Used to throttle touchpad scroll events.
var _last_accepted_scroll_event_time := 0
var _is_in_browser := OS.get_name() == "HTML5"

# Control node to move when scrolling.
@onready var _content: Control = get_child(get_child_count() - 1) as Control
@onready var _scroll_sensitivity := 1.0


func _ready() -> void:
	set_process(false)

	_update_max_position_y()
	_content.resized.connect(_update_max_position_y)

	get_v_scroll_bar().scrolling.connect(_on_VScrollBar_scrolling)

	var user_profile := UserProfiles.get_profile()
	_scroll_sensitivity = user_profile.scroll_sensitivity
	user_profile.scroll_sensitivity_changed.connect(_on_UserProfile_scroll_sensitivity_changed)


func _process(delta: float) -> void:
	var distance_to_target = _current_scroll.distance_to(_target_position)
	if distance_to_target <= ARRIVE_THRESHOLD * scroll_speed / SPEED_BASE:
		set_process(false)
		return

	var speed_multiplier := maxf((distance_to_target - ACCELERATE_DISTANCE_THRESHOLD) / SPEED_DISTANCE_DIVISOR, 1.0)
	scroll_speed = SPEED_BASE * speed_multiplier
	arrive_distance = ARRIVE_DISTANCE_BASE * speed_multiplier

	var direction := _current_scroll.direction_to(_target_position)
	var desired_velocity := direction * scroll_speed
	if distance_to_target < arrive_distance:
		desired_velocity = desired_velocity.lerp(Vector2.ZERO, 1.0 - distance_to_target / arrive_distance)

	var steering := desired_velocity - _velocity
	_velocity += steering / 2.0
	# Prevents scrolling from overshooting when the framerate goes down.
	if _velocity.length() * delta > distance_to_target:
		_velocity = _velocity.normalized() * distance_to_target / delta

	_current_scroll += _velocity * delta
	scroll_vertical = _current_scroll.y


func _gui_input(event: InputEvent) -> void:
	# Used to throttle scroll events that are too fast, which happens with some
	# touchpads.
	var can_mouse_scroll := true
	if _is_in_browser:
		can_mouse_scroll = Time.get_ticks_msec() > _last_accepted_scroll_event_time + TIME_MSEC_BETWEEN_SCROLL_EVENTS

	if event.is_action_pressed("scroll_up_one_page"):
		scroll_page_up()
	elif event.is_action_pressed("scroll_down_one_page"):
		scroll_page_down()
	elif event.is_action_pressed("scroll_to_top"):
		scroll_to_top()
	elif event.is_action_pressed("scroll_to_bottom"):
		scroll_to_bottom()
	elif can_mouse_scroll:
		if event.is_action("scroll_up") and event.pressed:
			scroll_up()
		elif event.is_action("scroll_down") and event.pressed:
			scroll_down()


func scroll_up() -> void:
	_set_target_position(_target_position + Vector2.UP * MOUSE_SCROLL_STEP * _scroll_sensitivity)
	_last_accepted_scroll_event_time = Time.get_ticks_msec()


func scroll_down() -> void:
	_set_target_position(_target_position + Vector2.DOWN * MOUSE_SCROLL_STEP * _scroll_sensitivity)
	_last_accepted_scroll_event_time = Time.get_ticks_msec()


func scroll_page_up() -> void:
	_set_target_position(_target_position + Vector2.UP * size.y)


func scroll_page_down() -> void:
	_set_target_position(_target_position + Vector2.DOWN * size.y)


func scroll_to_top() -> void:
	_set_target_position(Vector2.ZERO)


func scroll_to_bottom() -> void:
	_set_target_position(Vector2.DOWN * _max_position_y)


# Override default implementation to keep local properties in sync.
func set_v_scroll_override(value: int) -> void:
	set_v_scroll(value)

	if is_processing():
		set_process(false)
	_current_scroll.y = scroll_vertical
	_target_position.y = scroll_vertical


func _set_target_position(new_position: Vector2) -> void:
	_target_position = new_position
	_target_position.y = clamp(_target_position.y, 0.0, _max_position_y)
	set_process(true)


func _update_max_position_y() -> void:
	_max_position_y = _content.size.y - size.y


func _on_VScrollBar_scrolling() -> void:
	if is_processing():
		set_process(false)
	_current_scroll.y = scroll_vertical
	_target_position.y = scroll_vertical


func _on_UserProfile_scroll_sensitivity_changed(new_value: float) -> void:
	_scroll_sensitivity = new_value
