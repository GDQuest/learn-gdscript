# Wrapper class to make sure whichever control we put as the main screen plugin,
# it is correctly displayed. Also gives easy access to EditorPlugin instance.
tool
extends MarginContainer

var plugin_instance: EditorPlugin

const ROOT_SCENE: PackedScene = preload("../ui/CourseEditor.tscn")


func _init() -> void:
	size_flags_vertical = SIZE_EXPAND_FILL


func _ready() -> void:
	var root := ROOT_SCENE.instance()
	add_child(root)
	root.editor_interface = plugin_instance.get_editor_interface()
