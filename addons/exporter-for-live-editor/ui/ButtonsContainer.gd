tool
# A container for buttons that simplifies button groups.
#
# This extends `Container` so you can use it with any container
# type, instead of constricting it to a specific container.
#
# You can add other widgets to the container, only buttons will
# be considered as valid options.
#
# options values:
#
# If you supply an array of values, those values will be used when an
# option is selected. Otherwise, the button's meta.value property
# (`button.set_meta("value", button_value)`) will be attempted.
# Lastly, the button's text will be used
#
# No value gets selected by default, so it is advised to set a
# value (or use `select_first()` to select the first value)
extends Container

# sent when an option is selected. The `value` type will depend
# on the system used to retrieve the value. This is generally
# simply the button's text, unless you provided a value manually
signal item_selected(value)

# You can use this to specify values for the buttons. Make sure
# there are as many values as there are buttons
export var values: Array = []

# sets or retrieves the current value.
var selected_value setget set_selected_value, get_selected_value
# if you want to set a value, but don't want to trigger signals,
# set this to false before (and set it back to true after)
# internally used by `select_first()`.
var send_signals_on_press := true

# will be shared by all buttons in the container
var _button_group := ButtonGroup.new()
# holds an index of values so we can set a button as `pressed`
# by providing a value
var _values_index = {}


func _ready() -> void:
	var buttons = []

	for child in get_children():
		if child is BaseButton:
			buttons.append(child)

	for i in buttons.size():
		var button := buttons[i] as BaseButton
		button.group = _button_group
		button.toggle_mode = true
		var button_value = _get_button_value(button, i)
		_values_index[button_value] = button
		button.set_meta("value", button_value)
		button.connect("pressed", self, "_on_button_pressed", [button_value])
	

# Retrieves a value associated with a button; called on _ready when
# looping over buttons. Override in subclasses for custom value
# retrieval logic
func _get_button_value(button: BaseButton, value_index: int):
	if value_index >= 0 and value_index < values.size():
		return values[value_index]
	elif button.has_meta("value"):
		return button.get_meta("value")
	elif button is Button and button.text != "":
		return button.text
	else:
		assert(
			false,
			(
				'button %s in %s has no corresponding value, no text value, and no "data" meta property'
				% [value_index, get_path()]
			)
		)


# Called when a button is pressed. `button_value` cannot be
# statically determined because it depends on button value
# retrieval logic.
func _on_button_pressed(button_value) -> void:
	if not send_signals_on_press:
		return
	emit_signal("item_selected", button_value)


# Retrieves an option value by ordinal index.
func get_value_by_index(index: int):
	var keys = _values_index.keys()
	var is_valid_index = index >= 0 and index < keys.size()
	assert(is_valid_index, "index %s is not valid" % [index])
	if is_valid_index:
		return keys[index]


# If you know your button order, using this can be safer than
# using strings to select options
func set_selected_value_by_index(index: int) -> void:
	var value = get_value_by_index(index)
	if value != null:
		set_selected_value(value)


# Selects the first button
func select_first() -> void:
	send_signals_on_press = false
	set_selected_value_by_index(0)
	send_signals_on_press = true


# Selects the last button
func select_last() -> void:
	send_signals_on_press = false
	set_selected_value_by_index(values.size() - 1)
	send_signals_on_press = true


func set_selected_value(new_value) -> void:
	selected_value = new_value
	if not is_inside_tree():
		yield(self, "ready")
	assert(
		new_value in _values_index,
		"value %s is not a valid value of the button group %s" % [new_value, get_path()]
	)
	if new_value in _values_index:
		var button := _values_index[new_value] as BaseButton
		button.pressed = true



func get_pressed_button() -> BaseButton:
	return _button_group.get_pressed_button()


func get_selected_value():
	return selected_value
