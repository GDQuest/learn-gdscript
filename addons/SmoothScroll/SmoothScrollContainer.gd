# Adds smooth scrolling support to vertical ScrollContainer nodes.
#
# This works by moving a direct child of the container. See `_content`.
class_name SmoothScrollContainer
extends ScrollContainer

# Amount of pixels to offset the scroll target when scrolling with the mouse
# wheel or the touchpad.
const MOUSE_SCROLL_STEP := 50.0
const PAGE_HEIGHT := 800.0
# When the velocity's squared length gets below this value, we set it to zero.
const ARRIVE_THRESHOLD := 12.0
const ARRIVE_DISTANCE := 200.0

var max_speed := 3000.0

# Current velocity of the content node.
var _velocity := Vector2(0, 0)
# Current position of content node. We use this to track and force the child
# node's position as directly updating the node's position conflicts with the
# ScrollContainer's native behavior.
var _content_position := Vector2.ZERO
var _target_position := Vector2.ZERO setget _set_target_position

# Control node to move when scrolling.
onready var _content: Control = get_child(get_child_count() - 1)
onready var _scroll_sensitivity := 1.0

onready var _max_position_y := _content.rect_size.y - rect_size.y / 2.0


func _ready() -> void:
	set_process(false)
	get_v_scrollbar().connect("scrolling", self, "set_process", [false])

	var user_profile := UserProfiles.get_profile()
	_scroll_sensitivity = user_profile.scroll_sensitivity
	user_profile.connect(
		"scroll_sensitivity_changed", self, "_on_UserProfile_scroll_sensitivity_changed"
	)


func _process(delta: float) -> void:
	var direction := _content_position.direction_to(_target_position)
	var desired_velocity := direction * max_speed
	var distance_to_target = _content_position.distance_to(_target_position)
	if distance_to_target < ARRIVE_DISTANCE:
		desired_velocity *= distance_to_target / ARRIVE_DISTANCE

	var steering := desired_velocity - _velocity
	_velocity += steering / 3.5

	_content_position += _velocity * delta
	scroll_vertical = _content_position.y

	if distance_to_target <= ARRIVE_THRESHOLD:
		set_process(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_WHEEL_DOWN:
				scroll_down(MOUSE_SCROLL_STEP)
			BUTTON_WHEEL_UP:
				scroll_up(MOUSE_SCROLL_STEP)


func scroll_up(amount: float) -> void:
	_set_target_position(_target_position + Vector2.UP * amount * _scroll_sensitivity)


func scroll_down(amount: float) -> void:
	_set_target_position(_target_position + Vector2.DOWN * amount * _scroll_sensitivity)


func scroll_page_up() -> void:
	_set_target_position(_target_position + Vector2.UP * PAGE_HEIGHT)


func scroll_page_down() -> void:
	_set_target_position(_target_position + Vector2.DOWN * PAGE_HEIGHT)


func scroll_to_top() -> void:
	_set_target_position(Vector2.ZERO)


func scroll_to_bottom() -> void:
	_set_target_position(Vector2.DOWN * _max_position_y)


func _set_target_position(new_position: Vector2) -> void:
	_target_position = new_position
	_target_position.y = clamp(_target_position.y, 0.0, _max_position_y)
	set_process(true)


func _on_UserProfile_scroll_sensitivity_changed(new_value: float) -> void:
	_scroll_sensitivity = new_value
