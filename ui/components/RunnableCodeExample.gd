# Displays a scene with a GDScript code example. If the scene's root has a
# `run()` function, pressing the run button will call the function.
tool
class_name RunnableCodeExample
extends HBoxContainer

signal scene_instance_set

const ERROR_NO_RUN_FUNCTION := "Scene %s doesn't have a run() function. The Run button won't work."

export var scene: PackedScene setget set_scene
export(String, MULTILINE) var gdscript_code := "" setget set_code
export var center_in_frame := true setget set_center_in_frame
export var run_button_label := "" setget set_run_button_label

var _scene_instance: CanvasItem setget _set_scene_instance

var _base_text_font_size := preload("res://ui/theme/fonts/font_text.tres").size

onready var _gdscript_text_edit := $GDScriptCode as TextEdit
onready var _run_button := $Frame/HBoxContainer/RunButton as Button
onready var _reset_button := $Frame/HBoxContainer/ResetButton as Button
onready var _frame_container := $Frame/PanelContainer as Control
onready var _sliders := $Frame/Sliders as VBoxContainer

onready var _start_code_example_height := _gdscript_text_edit.rect_size.y


func _ready() -> void:
	Events.connect("font_size_scale_changed", self, "_update_gdscript_text_edit_width")
	if not Engine.editor_hint:
		_update_gdscript_text_edit_width(UserProfiles.get_profile().font_size_scale)

	_run_button.connect("pressed", self, "run")
	_reset_button.connect("pressed", self, "reset")
	_frame_container.connect("resized", self, "_center_scene_instance")

	CodeEditorEnhancer.enhance(_gdscript_text_edit)
	_gdscript_text_edit.add_color_region("[=", "]", CodeEditorEnhancer.COLOR_COMMENTS)

	_gdscript_text_edit.visible = not gdscript_code.empty()

	# If there's no scene but there's an instance as a child of
	# RunnableCodeExample, we use this as the scene instance.
	#
	# This simplifies the process of creating code examples.
	if not Engine.editor_hint and not scene and get_child_count() > 2:
		var last_child = get_child(get_child_count() - 1)
		assert(last_child != _gdscript_text_edit and last_child != _frame_container)
		remove_child(last_child)
		_set_scene_instance(last_child)


func _get_configuration_warning() -> String:
	if not scene:
		return "This node needs a scene to display."
	elif _scene_instance and not _scene_instance.has_method("run"):
		return ERROR_NO_RUN_FUNCTION % [_scene_instance.filename]
	return ""


func run() -> void:
	assert(_scene_instance.has_method("run"), "Node %s does not have a run method" % [get_path()])
	# warning-ignore:unsafe_method_access
	_scene_instance.run()
	if _scene_instance.has_method("wrap_inside_frame"):
		# warning-ignore:unsafe_method_access
		_scene_instance.wrap_inside_frame(_frame_container.get_rect())


func reset() -> void:
	if _scene_instance.has_method("reset"):
		_scene_instance.call("reset")
	_center_scene_instance()


func set_code(new_gdscript_code: String) -> void:
	gdscript_code = new_gdscript_code
	if not _gdscript_text_edit:
		yield(self, "ready")
	_gdscript_text_edit.text = new_gdscript_code


func set_scene(new_scene: PackedScene) -> void:
	scene = new_scene
	# Work around an issue where Godot considers the property got overriden in a
	# scene and calls the setter, freeing the _scene_instance.
	if not scene:
		return

	if not is_inside_tree():
		yield(self, "ready")

	if _scene_instance and is_instance_valid(_scene_instance):
		_scene_instance.queue_free()

	if scene:
		_set_scene_instance(scene.instance())


func set_center_in_frame(value: bool) -> void:
	center_in_frame = value
	_center_scene_instance()


func set_run_button_label(new_text: String) -> void:
	run_button_label = new_text
	if not is_inside_tree():
		yield(self, "ready")

	if not run_button_label.empty():
		_run_button.text = run_button_label


func create_slider_for(property_name, min_value := 0.0, max_value := 100.0, step := 1.0) -> HSlider:
	if not _scene_instance:
		yield(self, "scene_instance_set")
	var box := HBoxContainer.new()
	var label := Label.new()
	var value_label := Label.new()
	var slider := HSlider.new()
	var property_value = _scene_instance.get(property_name)

	_sliders.add_child(box)
	box.add_child(label)
	box.add_child(slider)
	box.add_child(value_label)

	label.text = property_name.capitalize()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.value = property_value
	slider.step = step
	slider.rect_min_size.x = 100.0
	slider.connect("value_changed", self, "_set_instance_value", [property_name, value_label])
	_set_instance_value(property_value, property_name, value_label)
	return slider


# Using this proxy function is required as the value emitted by the signal
# will always be the first argument.
func _set_instance_value(value: float, property_name: String, value_label: Label) -> void:
	_scene_instance.set(property_name, value)
	value_label.text = String(value)


func _center_scene_instance() -> void:
	if not center_in_frame or not _scene_instance:
		return
	if _scene_instance is Node2D:
		# warning-ignore:unsafe_property_access
		_scene_instance.position = _frame_container.rect_size / 2


func _set_scene_instance(new_scene_instance: CanvasItem) -> void:
	_scene_instance = new_scene_instance
	emit_signal("scene_instance_set")
	_scene_instance.show_behind_parent = true
	_frame_container.add_child(_scene_instance)
	_center_scene_instance()

	_reset_button.visible = _scene_instance.has_method("reset")
	if _scene_instance.has_method("run"):
		_run_button.show()
	elif _run_button.visible:
		_run_button.hide()
		printerr(ERROR_NO_RUN_FUNCTION % [_scene_instance.filename])


func _update_gdscript_text_edit_width(new_font_scale: int) -> void:
	var font_size_multiplier := (
		float(_base_text_font_size + new_font_scale * 2)
		/ _base_text_font_size
	)
	_gdscript_text_edit.rect_min_size.y = _start_code_example_height * font_size_multiplier
	# Forces the text wrapping to update. Without this, the code can overflow
	# the container when changing the font size.
	# TODO: There is some computation error in the TextEdit, it seems. Need to investigate it further.
	pass
