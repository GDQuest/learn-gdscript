tool
extends "res://addons/exporter-for-live-editor/ui/Check.gd"

var _button := Button.new()
var _progress_bar := ProgressBar.new()

export var scene_file: PackedScene setget set_scene_file
export var button_text := "Go to Lesson" setget set_button_text
export var progress := 0 setget set_progress

func _init() -> void:
	
	_progress_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(_progress_bar)
	
	# TODO: unhide once score saving works
	_progress_bar.visible = false
	
	add_child(_button)
	
	if Engine.editor_hint:
		return
	
	UserProfiles.connect("progress_changed", self, "_on_exercise_progress_changed")


func _ready() -> void:
	if Engine.editor_hint:
		return
	_load_progress()


func _load_progress() -> void:
	var _progress = UserProfiles.get_profile().get_exercise_progress(_get_scene_url())
	set_progress(_progress)


func _get_scene_url() -> String:
	return scene_file.resource_path if scene_file else ""


func set_scene_file(new_scene_file: PackedScene) -> void:
	scene_file = new_scene_file
	var _scene_url := scene_file.resource_path
	if _button.is_connected("pressed", NavigationManager, "open_url"):
		_button.disconnect("pressed", NavigationManager, "open_url")
	_button.connect("pressed", NavigationManager, "open_url", [_scene_url])


func set_button_text(new_text: String) -> void:
	button_text = new_text
	_button.text = new_text


func set_progress(new_progress: int) -> void:
	progress = new_progress
	_progress_bar.value = new_progress


func _on_exercise_progress_changed(exercise: String, exercise_progress: int) -> void:
	if exercise == _get_scene_url():
		set_progress(exercise_progress)
