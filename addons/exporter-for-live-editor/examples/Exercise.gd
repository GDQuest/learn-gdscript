extends Control

const SceneFiles := preload("../collections/SceneFiles.gd")
const ScriptHandler := preload("../collections/ScriptHandler.gd")
const ScriptSlice := preload("../collections/ScriptSlice.gd")
const SlicesList := preload("../ui/SlicesList.gd")
const SliceEditor := preload("../ui/SliceEditor.gd")
const GameViewport := preload("../ui/GameViewport.gd")
const GameConsole := preload("../ui/GameConsole.gd")
const Check := preload("../ui/Goal.gd")
const ScriptVerifier := preload("../lsp/ScriptVerifier.gd")
const LanguageServerError := preload("../lsp/LanguageServerError.gd")
const ValidationManager := preload("../validation/ValidationManager.gd")

onready var validation_manager := $ValidationManager as ValidationManager
onready var slice_editor := $EditorContainer/VBoxContainer/SliceEditor as SliceEditor
onready var game_viewport := $GameContainer/VSplitContainer/GameViewport as GameViewport
onready var save_button := $EditorContainer/VBoxContainer/HBoxContainer/SaveButton as Button
onready var pause_button := $EditorContainer/VBoxContainer/HBoxContainer/PauseButton as Button
onready var game_console := $GameContainer/VSplitContainer/Console as GameConsole
onready var title_label := $LessonContainer/LessonRequirements/Title as Label
onready var progress_bar := $LessonContainer/LessonRequirements/ProgressBar as ProgressBar
onready var goal_rich_text_label := (
	$LessonContainer/LessonRequirements/ScrollContainer/VBoxContainer/Goal
	as RichTextLabel
)
onready var checks_container := (
	$LessonContainer/LessonRequirements/ScrollContainer/VBoxContainer/Checks
	as Revealer
)

export var title := "Title" setget set_title
export var goal := "Goal" setget set_goal
export var progress := 0.0 setget set_progress
export var scene_files: Resource setget set_scene_files, get_scene_files
export (String, FILE, "*.gd") var exported_script_path: String setget set_exported_script_path
export var slice_name: String setget set_slice_name

var current_slice: ScriptSlice
var current_script_handler: ScriptHandler


func _ready() -> void:
	_instantiate_checks()
	save_button.connect("pressed", self, "_on_save_button_pressed")
	pause_button.connect("pressed", self, "_on_pause_button_pressed")


func _instantiate_checks():
	for child in get_children():
		if child is Validator:
			var validator := child as Validator
			var check := Check.new()
			check.text = validator.title
			#check.size_flags_horizontal = SIZE_EXPAND_FILL
			remove_child(validator)
			check.add_child(validator)
			checks_container.add_child(check)


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
		push_error("scene_files %s is not a valid instance of SceneFiles" % [new_scene_files])
		return
	scene_files = new_scene_files
	if not is_inside_tree():
		yield(self, "ready")
	game_viewport.scene_files = scene_files


func get_scene_files() -> SceneFiles:
	return scene_files as SceneFiles


func get_script_handler() -> ScriptHandler:
	var file := get_scene_files().get_file(exported_script_path)
	return file


func get_slice() -> ScriptSlice:
	var script_handler := get_script_handler()
	if script_handler:
		var slice = script_handler.get_slice(slice_name)
		return slice
	return null


func set_exported_script_path(path: String) -> void:
	exported_script_path = path
	if not scene_files:
		push_error("no scene files is set")
	var script_handler := get_script_handler()
	if script_handler == null:
		push_error(
			"File %s is not included in the exported scene %s" % [exported_script_path, scene_files]
		)


func set_slice_name(new_slice_name: String) -> void:
	if not scene_files:
		push_error("no scene files is set")
	if not exported_script_path:
		push_error("setting a slice without a file path")
	slice_name = new_slice_name
	var slice := get_slice()
	if slice == null:
		push_error(
			(
				"Slice %s is not included in the exported script %s"
				% [slice_name, get_script_handler()]
			)
		)
	if not is_inside_tree():
		yield(self, "ready")
	slice_editor.script_slice = slice


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	title_label.title = title


func set_goal(new_goal: String) -> void:
	goal = new_goal
	if not is_inside_tree():
		yield(self, "ready")
	goal_rich_text_label.bbcode_text = goal


func set_progress(new_progress: float) -> void:
	progress = new_progress
	if not is_inside_tree():
		yield(self, "ready")
	progress_bar.value = progress
