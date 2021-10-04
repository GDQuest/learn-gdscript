## Creates a list of Buttons corresponding to `SceneFiles`' `ScriptSlice`s.
## When pressed, those buttons dispatch a signal with the selected slice.
## This can be used for as a starting point for listing all slices
## in a SceneFiles resource.
## 
## It extends Node to be flexibly applied to any container, or even
## a node that doesn't descend from Container.
extends Node

const SceneFiles := preload("../collections/SceneFiles.gd")
const ScriptHandler := preload("../collections/ScriptHandler.gd")
const ScriptSlice := preload("../collections/ScriptSlice.gd")

signal slice_selected(sript_slice)

# Expects the resource to be a SceneFiles resource instance
export (Resource) var exported_scene: Resource setget set_exported_scene, get_exported_scene

var selected_value setget set_selected_value, get_selected_value
var _button_group := ButtonGroup.new()
var _buttons_index := {}


func set_exported_scene(new_scene_files: Resource) -> void:
	exported_scene = new_scene_files
	assert(new_scene_files != null, "no scene slices provided")
	var scene_files := new_scene_files as SceneFiles
	assert(
		scene_files is SceneFiles,
		"file '%s' is not an instance of SceneFiles." % [new_scene_files.resource_path]
	)
	_clean()
	_read_scene_files(scene_files)


func get_exported_scene() -> SceneFiles:
	return exported_scene as SceneFiles


func _read_scene_files(scene_files: SceneFiles) -> void:
	for _script_handler in scene_files:
		# repetition for getting proper typing
		var script_handler := scene_files.current()
		for _slice_name in script_handler:
			# repetition for getting proper typing
			var current_slice := script_handler.current()
			_create_element(script_handler, current_slice)


# This method is called internally for each slice.
# by default, creates a button and appends it to children
# Override it in inherited classes to change the behavior
func _create_element(script: ScriptHandler, slice: ScriptSlice):
	var button = Button.new()
	button.text = script.name + ":" + slice.name
	button.toggle_mode = true
	button.group = _button_group
	_buttons_index[button.text] = button
	var signal_args = ["slice_selected", script, slice]
	button.connect("pressed", self, "emit_signal", signal_args)
	add_child(button)


# Removes all children
func _clean() -> void:
	_button_group = ButtonGroup.new()
	_buttons_index = {}
	for child in get_children():
		remove_child(child)
		child.queue_free()


func get_selected_value() -> BaseButton:
	return _button_group.get_pressed_button()


func select_first() -> void:
	var button: BaseButton = _button_group.get_buttons()[0]
	if button:
		button.pressed
	else:
		push_warning("select_first called, but there are no buttons")


func set_selected_value(new_value) -> void:
	if new_value in _buttons_index:
		var button := _buttons_index[new_value] as BaseButton
		button.pressed = true
