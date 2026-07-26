# Adds smooth scrolling support to vertical ScrollContainer nodes.
#
# This works by moving a direct child of the container. See `_content`.
@icon("res://ui/assets/nodes/smooth_scroll_container.svg")
class_name SmoothScrollContainer
extends ScrollContainer

## Amount of pixels to offset the scroll target for one step with the mouse
## wheel, by default.
const MOUSE_SCROLL_STEP := 80.0
const SCROLL_SPEED_MOUSE_WHEEL := 3000.0
const SCROLL_SPEED_PAGE_UP_DOWN := 5000.0
const SCROLL_SMOOTHING_RATE := 12.0
const JUMP_SCROLL_DURATION := 0.4
const ARRIVE_DISTANCE := 0.5
const MAX_WHEEL_INPUT_BUFFER := 600.0

# Current velocity of the content node.
var _scroll_velocity := Vector2.ZERO
# Current scroll coordinated. We use this to track and force the scrollbars to
# specific scrolling as directly updating the scroll properties conflicts with
# the ScrollContainer's native behavior.
var _current_scroll_position := Vector2.ZERO
var _target_scroll_position := Vector2.ZERO:
	set = _set_target_scroll_position
var _maximum_scroll_position_y := 0.0
# Accumulates an amount of pixels to offset the scroll target based on user
# input. Consumed every frame in _process() when _process() is active.
var _pending_scroll_difference := 0.0
var _maximum_scroll_speed := SCROLL_SPEED_MOUSE_WHEEL
var _scroll_smoothing_rate := SCROLL_SMOOTHING_RATE
var _wheel_scroll_budget := MOUSE_SCROLL_STEP
var _last_wheel_scroll_direction := 0.0

# Control node to move when scrolling.
@onready var _content: Control = get_child(get_child_count() - 1) as Control
@onready var _scroll_sensitivity := 1.0


func _ready() -> void:
	set_process(false)



	var _update_max_scroll_position := func() -> void:
		_maximum_scroll_position_y = maxf(_content.size.y - size.y, 0.0)
	_update_max_scroll_position.call()
	_content.resized.connect(_update_max_scroll_position)

	# The user is grabbing the scrollbar, so we need to stop processing.
	get_v_scroll_bar().scrolling.connect(
		func _on_VScrollBar_scrolling() -> void:
			if is_processing():
				set_process(false)
			_pending_scroll_difference = 0.0
			_scroll_velocity = Vector2.ZERO
			_current_scroll_position.y = scroll_vertical
			_target_scroll_position.y = scroll_vertical,
	)

	var user_profile := UserProfiles.get_profile()
	_scroll_sensitivity = user_profile.scroll_sensitivity
	_maximum_scroll_speed = SCROLL_SPEED_MOUSE_WHEEL * _scroll_sensitivity
	_wheel_scroll_budget = MAX_WHEEL_INPUT_BUFFER * _scroll_sensitivity
	user_profile.scroll_sensitivity_changed.connect(
		func (new_value: float) -> void:
			_scroll_sensitivity = new_value,
	)


func _process(delta: float) -> void:
	_wheel_scroll_budget = minf(
		_wheel_scroll_budget + SCROLL_SPEED_MOUSE_WHEEL * _scroll_sensitivity * delta,
		MAX_WHEEL_INPUT_BUFFER * _scroll_sensitivity,
	)

	if not is_zero_approx(_pending_scroll_difference):
		_set_target_scroll_position(_target_scroll_position + Vector2.DOWN * _pending_scroll_difference)
		_pending_scroll_difference = 0.0

	var distance_to_target := absf(_current_scroll_position.y - _target_scroll_position.y)
	if distance_to_target <= ARRIVE_DISTANCE:
		_current_scroll_position = _target_scroll_position
		_scroll_velocity = Vector2.ZERO
		_maximum_scroll_speed = SCROLL_SPEED_MOUSE_WHEEL * _scroll_sensitivity
		_scroll_smoothing_rate = SCROLL_SMOOTHING_RATE
		_wheel_scroll_budget = MAX_WHEEL_INPUT_BUFFER * _scroll_sensitivity
		scroll_vertical = roundi(_current_scroll_position.y)
		set_process(false)
		return

	# Controls how quickly the current position follows the target position.
	var smoothing_weight := 1.0 - exp(-_scroll_smoothing_rate * delta)
	var desired_scroll_y := lerpf(_current_scroll_position.y, _target_scroll_position.y, smoothing_weight)

	_scroll_velocity.y = clampf(
		(desired_scroll_y - _current_scroll_position.y) / delta,
		-_maximum_scroll_speed,
		_maximum_scroll_speed,
	)
	_current_scroll_position.y += _scroll_velocity.y * delta
	scroll_vertical = roundi(_current_scroll_position.y)


func _gui_input(event: InputEvent) -> void:
	if handle_keyboard_scroll(event):
		accept_event()
	else:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event and mouse_button_event.is_action("scroll_up") and mouse_button_event.pressed:
			_accumulate_pending_scroll_in_direction(-1.0, mouse_button_event.factor)
			accept_event()
		elif mouse_button_event and mouse_button_event.is_action("scroll_down") and mouse_button_event.pressed:
			_accumulate_pending_scroll_in_direction(1.0, mouse_button_event.factor)
			accept_event()


## Handles keyboard actions that move the whole scrollable page.
##
## Returns true when the event was a page-scroll action. The lesson screen calls
## this directly to allow pressing scroll shortcuts regardless of current UI
## focus.
func handle_keyboard_scroll(event: InputEvent) -> bool:
	if event.is_action_pressed("scroll_up_one_page"):
		_pending_scroll_difference = 0.0
		_wheel_scroll_budget = MAX_WHEEL_INPUT_BUFFER * _scroll_sensitivity
		_maximum_scroll_speed = SCROLL_SPEED_PAGE_UP_DOWN
		_scroll_smoothing_rate = SCROLL_SMOOTHING_RATE
		_set_target_scroll_position(_target_scroll_position + Vector2.UP * size.y)
		return true
	elif event.is_action_pressed("scroll_down_one_page"):
		_pending_scroll_difference = 0.0
		_wheel_scroll_budget = MAX_WHEEL_INPUT_BUFFER * _scroll_sensitivity
		_maximum_scroll_speed = SCROLL_SPEED_PAGE_UP_DOWN
		_scroll_smoothing_rate = SCROLL_SMOOTHING_RATE
		_set_target_scroll_position(_target_scroll_position + Vector2.DOWN * size.y)
		return true
	elif event.is_action_pressed("scroll_to_top"):
		_pending_scroll_difference = 0.0
		_wheel_scroll_budget = MAX_WHEEL_INPUT_BUFFER * _scroll_sensitivity
		_set_target_scroll_position(Vector2.ZERO)
		var jump_distance := absf(_current_scroll_position.y - _target_scroll_position.y)
		_scroll_smoothing_rate = log(maxf(jump_distance / ARRIVE_DISTANCE, 1.0)) / JUMP_SCROLL_DURATION
		_maximum_scroll_speed = jump_distance * _scroll_smoothing_rate
		return true
	elif event.is_action_pressed("scroll_to_bottom"):
		_pending_scroll_difference = 0.0
		_wheel_scroll_budget = MAX_WHEEL_INPUT_BUFFER * _scroll_sensitivity
		_set_target_scroll_position(Vector2.DOWN * _maximum_scroll_position_y)
		var jump_distance := absf(_current_scroll_position.y - _target_scroll_position.y)
		_scroll_smoothing_rate = log(maxf(jump_distance / ARRIVE_DISTANCE, 1.0)) / JUMP_SCROLL_DURATION
		_maximum_scroll_speed = jump_distance * _scroll_smoothing_rate
		return true
	return false


## call this function when you want to add one scroll step like the result of
## scrolling up or down by one increment using a touchpad or a mouse wheel. It
## updates the container's state and adds the scroll direction and factor to the
## pending scroll amount that will get consumed in the next frame.
##
## scroll_direction should be -1.0 for scroll up and 1.0 for scroll down.
## factor should be the scroll factor from the input event (it is especially
## important for the feel of scrolling with touchpads).
func _accumulate_pending_scroll_in_direction(scroll_direction: float, factor: float) -> void:
	_maximum_scroll_speed = SCROLL_SPEED_MOUSE_WHEEL * _scroll_sensitivity
	_scroll_smoothing_rate = SCROLL_SMOOTHING_RATE
	var scroll_factor := factor if factor > 0.0 else 1.0
	var requested_scroll_delta := scroll_factor * MOUSE_SCROLL_STEP * _scroll_sensitivity
	var accepted_scroll_delta := minf(requested_scroll_delta, _wheel_scroll_budget)
	_wheel_scroll_budget -= accepted_scroll_delta
	_pending_scroll_difference += scroll_direction * accepted_scroll_delta
	set_process(true)


# Override default implementation to keep local properties in sync.
func set_v_scroll_override(value: int) -> void:
	set_v_scroll(value)

	if is_processing():
		set_process(false)
	_pending_scroll_difference = 0.0
	_scroll_velocity = Vector2.ZERO
	_maximum_scroll_speed = SCROLL_SPEED_MOUSE_WHEEL * _scroll_sensitivity
	_scroll_smoothing_rate = SCROLL_SMOOTHING_RATE
	_wheel_scroll_budget = MAX_WHEEL_INPUT_BUFFER * _scroll_sensitivity
	_current_scroll_position.y = scroll_vertical
	_target_scroll_position.y = scroll_vertical


func _set_target_scroll_position(new_position: Vector2) -> void:
	_target_scroll_position = new_position
	_target_scroll_position.y = clamp(_target_scroll_position.y, 0.0, _maximum_scroll_position_y)
	set_process(true)
