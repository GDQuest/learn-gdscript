tool
extends EditorPlugin

var _main_screen_plugin


func has_main_screen() -> bool:
	return true


func get_plugin_name() -> String:
	return "Course Builder"


func get_plugin_icon() -> Texture:
	return get_editor_interface().get_base_control().get_icon("EditorPlugin", "EditorIcons")


func _enter_tree() -> void:
	_main_screen_plugin = preload("plugins/MainScreenPlugin.gd").new()
	_main_screen_plugin.plugin_instance = self
	get_editor_interface().get_editor_viewport().add_child(_main_screen_plugin)
	make_visible(false)


func _exit_tree() -> void:
	get_editor_interface().get_editor_viewport().remove_child(_main_screen_plugin)


func make_visible(visible: bool) -> void:
	_main_screen_plugin.visible = visible
