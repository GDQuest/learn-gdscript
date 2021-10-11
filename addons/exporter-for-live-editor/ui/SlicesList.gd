# Creates a list of Buttons corresponding to `SceneFiles`' `ScriptSlice`s.
# When pressed, those buttons dispatch a signal with the selected slice.
# This can be used for as a starting point for listing all slices
# in a SceneFiles resource.
#
# It extends Node to be flexibly applied to any container, or even
# a node that doesn't descend from Container.
extends Node

const SceneFiles := preload("../collections/SceneFiles.gd")
const ScriptHandler := preload("../collections/ScriptHandler.gd")
const ScriptSlice := preload("../collections/ScriptSlice.gd")

signal slice_selected(script_handler, script_slice)

# Expects the resource to be a SceneFiles resource instance
export (Resource) var scene_files: Resource setget set_scene_files, get_scene_files

var selected_value setget set_selected_value, get_selected_value
var _button_group := ButtonGroup.new()
var _signal_vars_index := {}


func set_scene_files(new_scene_files: Resource) -> void:
	scene_files = new_scene_files
	assert(new_scene_files != null, "no scene slices provided")
	var scene_files := new_scene_files as SceneFiles
	assert(
		scene_files is SceneFiles,
		"file '%s' is not an instance of SceneFiles." % [new_scene_files.resource_path]
	)
	_clean()
	_read_scene_files(scene_files)


func get_scene_files() -> SceneFiles:
	return scene_files as SceneFiles


func _read_scene_files(scene_files: SceneFiles) -> void:
	for _script_handler in scene_files:
		# repetition for getting proper typing
		var script_handler := scene_files.current()
		for _slice_name in script_handler:
			# repetition for getting proper typing
			var current_slice := script_handler.current()
			_create_element(script_handler, current_slice)


func get_selected_value() -> BaseButton:
	return _button_group.get_pressed_button()


func select_first() -> void:
	var button: BaseButton = _button_group.get_buttons()[0]
	if button:
		set_selected_value(button.text)
	else:
		push_warning("select_first called, but there are no buttons")


func set_selected_value(new_value: String) -> void:
	if new_value in _signal_vars_index:
		var signal_vars := _signal_vars_index[new_value] as SignalVars
		signal_vars.button.pressed = true
		dispatch_value(signal_vars)


func dispatch_value(slice: SignalVars) -> void:
	emit_signal("slice_selected", slice.script_handler, slice.script_slice)


# Removes all children and resets the button group.
func _clean() -> void:
	_button_group = ButtonGroup.new()
	_signal_vars_index = {}
	for child in get_children():
		remove_child(child)
		child.queue_free()


# This method is called internally for each slice.
#
# By default, creates a button and appends it to children.
#
# Override in inherited classes to change the behavior.
func _create_element(script: ScriptHandler, slice: ScriptSlice):
	var button = Button.new()
	button.text = script.name + (("/" + slice.name) if slice.name else "")
	button.toggle_mode = true
	button.group = _button_group
	var signal_vars = SignalVars.new(button, script, slice)
	_signal_vars_index[button.text] = signal_vars
	button.connect("pressed", self, "dispatch_value", [signal_vars])
	add_child(button)


class SignalVars:
	extends Reference
	const ScriptHandler := preload("../collections/ScriptHandler.gd")
	const ScriptSlice := preload("../collections/ScriptSlice.gd")

	var button: Button
	var script_handler: ScriptHandler
	var script_slice: ScriptSlice

	func _init(_button: Button, handler: ScriptHandler, slice: ScriptSlice) -> void:
		button = _button
		script_handler = handler
		script_slice = slice
