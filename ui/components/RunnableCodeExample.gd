# Displays a scene with a GDScript code example. If the scene's root has a
# `run()` function, pressing the run button will call the function.
tool
extends HBoxContainer

const ERROR_NO_RUN_FUNCTION := "Scene %s doesn't have a run() function. The Run button won't work."

export var scene: PackedScene setget set_scene
export (String, MULTILINE) var gdscript_code := "" setget set_code
export var center_in_frame := true setget set_center_in_frame

var _scene_instance: Node

onready var _gdscript_text_edit := $GDScriptCode as TextEdit
onready var _run_button := $Frame/RunButton as Button
onready var _frame := $Frame as Control


func _ready() -> void:
	_run_button.connect("pressed", self, "run")
	_frame.connect("resized", self, "_center_scene_instance")

	CodeEditorEnhancer.enhance(_gdscript_text_edit)


func _get_configuration_warning() -> String:
	if not scene:
		return "This node needs a scene to display."
	elif _scene_instance and not _scene_instance.has_method("run"):
		return ERROR_NO_RUN_FUNCTION % [_scene_instance.filename]
	return ""


func run() -> void:
	_scene_instance.run()
	if _scene_instance.has_method("wrap_inside_frame"):
		_scene_instance.wrap_inside_frame(_frame.get_rect())


func set_code(new_gdscript_code: String) -> void:
	gdscript_code = new_gdscript_code
	if not _gdscript_text_edit:
		yield(self, "ready")
	_gdscript_text_edit.text = new_gdscript_code


func set_scene(new_scene: PackedScene) -> void:
	scene = new_scene
	if not is_inside_tree():
		yield(self, "ready")

	if _scene_instance and is_instance_valid(_scene_instance):
		_scene_instance.queue_free()

	if scene:
		_scene_instance = scene.instance()
		_scene_instance.show_behind_parent = true
		_frame.add_child(_scene_instance)
		_center_scene_instance()
		if _scene_instance.has_method("run"):
			_run_button.show()
		else:
			_run_button.hide()
			printerr(ERROR_NO_RUN_FUNCTION % [_scene_instance.filename])


func set_center_in_frame(value: bool) -> void:
	center_in_frame = value
	_center_scene_instance()


func _center_scene_instance() -> void:
	if not center_in_frame or not _scene_instance:
		return
	_scene_instance.position = _frame.rect_size / 2
