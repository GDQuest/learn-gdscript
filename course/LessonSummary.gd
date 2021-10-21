tool
extends "res://addons/exporter-for-live-editor/ui/Check.gd"

var _button := Button.new()

export var scene_file: PackedScene setget set_scene_file
export var button_text := "Go to Lesson" setget set_button_text


func _init() -> void:
	_button.text = "Go to Lesson"
	add_child(_button)
	if Engine.editor_hint:
		return


func set_scene_file(new_scene_file: PackedScene) -> void:
	scene_file = new_scene_file
	var _scene_url := scene_file.resource_path
	if _button.is_connected("pressed", NavigationManager, "open_url"):
		_button.disconnect("pressed", NavigationManager, "open_url")
	_button.connect("pressed", NavigationManager, "open_url", [_scene_url])


func set_button_text(new_text: String) -> void:
	button_text = new_text
	_button.text = new_text
