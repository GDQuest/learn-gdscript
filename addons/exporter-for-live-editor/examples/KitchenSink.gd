extends Control

const SceneFiles := preload("../collections/SceneFiles.gd")
const ScriptHandler := preload("../collections/ScriptHandler.gd")
const ScriptSlice := preload("../collections/ScriptSlice.gd")
const SlicesList := preload("../ui/SlicesList.gd")
const SliceEditor := preload("../ui/SliceEditor.gd")
const GameViewport := preload("../ui/GameViewport.gd")
const GameConsole := preload("../ui/GameConsole.gd")
const ScriptVerifier := preload("../lsp/ScriptVerifier.gd")
const LanguageServerError := preload("../lsp/LanguageServerError.gd")
const ValidationManager := preload("../validation/ValidationManager.gd")

onready var slices_list := $VBoxContainer/SlicesList as SlicesList
onready var slice_editor := $VBoxContainer/SliceEditor as SliceEditor
onready var game_viewport := $VSplitContainer/GameViewport as GameViewport
onready var save_button := $VBoxContainer/HBoxContainer/SaveButton as Button
onready var pause_button := $VBoxContainer/HBoxContainer/PauseButton as Button
onready var game_console := $VSplitContainer/Console as GameConsole
onready var validation_manager := $ValidationManager as ValidationManager
onready var title_label := $LessonRequirements/Title as Label
onready var progress_bar := $LessonRequirements/ProgressBar as ProgressBar


export var title := "Title" setget set_title
export var progress := 0.0 setget set_progress
export var scene_files: Resource setget set_scene_files, get_scene_files

var current_slice: ScriptSlice
var current_script_handler: ScriptHandler


func _ready() -> void:
	save_button.connect("pressed", self, "_on_save_button_pressed")
	pause_button.connect("pressed", self, "_on_pause_button_pressed")

	slices_list.connect("slice_selected", self, "_on_slice_selected")


func _on_slice_selected(script_handler: ScriptHandler, script_slice: ScriptSlice) -> void:
	current_slice = script_slice
	current_script_handler = script_handler
	slice_editor.script_slice = script_slice
	validation_manager.script_slice = script_slice
	validation_manager.scene = game_viewport._scene


func _on_save_button_pressed() -> void:
	var script_path := current_script_handler.file_path
	var script_text := current_slice.current_full_text
	var nodes_paths := current_script_handler.nodes_paths
	var verifier := ScriptVerifier.new(self, script_text)
	verifier.test()
	var errors: Array = yield(verifier, "errors")
	if errors.size():
		slice_editor.errors = errors
		for index in errors.size():
			var error: LanguageServerError = errors[index]
			LiveEditorMessageBus.print_error(
				error.message,
				script_path,
				error.error_range.start.line,
				error.error_range.start.character
			)
		return
	script_text = LiveEditorMessageBus.replace_script(script_path, script_text)
	var script = GDScript.new()
	script.source_code = script_text
	var success = script.reload()
	if success != OK:
		LiveEditorMessageBus.print_error(
			"The script has an error, but the language server didn't catch it. Are you connected?",
			script_path
		)
		return
	game_viewport.update_nodes(script, nodes_paths)


func _on_pause_button_pressed() -> void:
	game_viewport.toggle_scene_pause()


func set_scene_files(new_scene_files: Resource) -> void:
	if scene_files == new_scene_files or not new_scene_files:
		return
	if not (new_scene_files is SceneFiles):
		push_error("scene_files %s is not a valid instance of SceneFiles"%[new_scene_files])
		return
	scene_files = new_scene_files
	if not is_inside_tree():
		yield(self, "ready")
	game_viewport.scene_files = scene_files
	slices_list.scene_files = scene_files
	slices_list.select_first()

func get_scene_files() -> SceneFiles:
	return scene_files as SceneFiles


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	title_label.title = title


func set_progress(new_progress: float) -> void:
	progress = new_progress
	if not is_inside_tree():
		yield(self, "ready")
	progress_bar.value = progress
