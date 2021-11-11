tool
class_name CourseExercise
extends Control

signal exercise_validated(is_valid)

const SceneFiles := preload("../collections/SceneFiles.gd")
const ScriptHandler := preload("../collections/ScriptHandler.gd")
const ScriptSlice := preload("../collections/ScriptSlice.gd")
const SlicesList := preload("../ui/SlicesList.gd")
const GameViewport := preload("../ui/GameViewport.gd")
const ValidatorCheck := preload("../ui/ValidatorCheck.gd")
const ScriptVerifier := preload("../lsp/ScriptVerifier.gd")
const LanguageServerError := preload("../lsp/LanguageServerError.gd")
const ValidationManager := preload("../validation/ValidationManager.gd")
const RevealerScene := preload("../ui/components/Revealer.tscn")

export var slice_properties: Resource setget set_slice_properties, get_slice_properties
export var title := "Title" setget set_title
export (String, MULTILINE) var goal := "Goal" setget set_goal
export (int, 0, 100) var progress := 0.0 setget set_progress
export var hints := PoolStringArray()
export (String, MULTILINE) var initial_editor_text := "" setget set_initial_editor_text, get_initial_editor_text

# if the text is changed and not saved, this will be "true"
var _code_editor_is_dirty := false

onready var _validation_manager := $ValidationManager as ValidationManager
onready var _game_container := find_node("Output") as PanelContainer
onready var _game_viewport := _game_container.find_node("GameViewport") as GameViewport

onready var _lesson_panel := find_node("LessonPanel") as LessonPanel
onready var _title_label := _lesson_panel.title_label
onready var _progress_bar := _lesson_panel.progress_bar
onready var _goal_rich_text_label := _lesson_panel.goal_rich_text_label
onready var _checks_container := _lesson_panel.checks_container
onready var _hints_container := _lesson_panel.hints_container

onready var _code_editor := find_node("CodeEditor") as CodeEditor
onready var _slice_editor := _code_editor._slice_editor
onready var _save_button := _code_editor.save_button
onready var _pause_button := _code_editor.pause_button


func _ready() -> void:
	rand_seed(0)
	randomize()
	if Engine.editor_hint:
		return
	_instantiate_checks()
	_instantiate_hints()
	_save_button.connect("pressed", self, "_on_save_button_pressed")
	_pause_button.connect("pressed", self, "_on_pause_button_pressed")
	_code_editor.connect("text_changed", self, "_on_code_editor_text_changed")


func take_over_slice() -> void:
	if slice_properties:
		LiveEditorState.current_slice = slice_properties
		_game_viewport.use_scene()
	else:
		push_warning("No slice property set on Exercise %s" % [get_path()])


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_distraction_free_mode"):
		var is_distraction_free := not _lesson_panel.visible
		_lesson_panel.visible = is_distraction_free
		_game_container.visible = is_distraction_free


func _instantiate_checks():
	var validators_number := 0
	for child in get_children():
		if child is Validator:
			validators_number += 1
			var validator := child as Validator
			var check := ValidatorCheck.new()
			check.text = validator.title
			remove_child(validator)
			check.add_child(validator)
			_checks_container.add_child(check)
			_validation_manager.add_check(check)

	if validators_number == 0:
		_checks_container.hide()


func _instantiate_hints():
	if hints.size() == 0:
		_hints_container.hide()

	for index in hints.size():
		var hint: Revealer = RevealerScene.instance()
		var hint_label := Label.new()
		hint_label.text = hints[index]
		hint.title = "Hint " + String(index + 1).pad_zeros(1)

		_hints_container.add_child(hint)
		hint.add_child(hint_label)
		hint.is_expanded = false

		hint.rect_min_size.x = _hints_container.rect_size.x - _hints_container.padding


func _on_save_button_pressed() -> void:
	var slice_properties := get_slice_properties()
	var script_path := slice_properties.get_script_properties().file_path
	var script_text := get_slice_properties().current_full_text
	var nodes_paths := slice_properties.get_script_properties().nodes_paths
	var verifier := ScriptVerifier.new(self, script_text)
	verifier.test()
	var errors: Array = yield(verifier, "errors")
	if errors.size():
		_slice_editor.errors = errors
		for index in errors.size():
			var error: LanguageServerError = errors[index]
			LiveEditorMessageBus.print_error(
				error.message,
				script_path,
				error.error_range.start.line,
				error.error_range.start.character
			)
		_send_exercise_validated_signal(false)
		return
	script_text = LiveEditorMessageBus.replace_script(script_path, script_text)
	var script = GDScript.new()
	script.source_code = script_text
	var script_is_valid = script.reload()
	if script_is_valid != OK:
		LiveEditorMessageBus.print_error(
			"The script has an error, but the language server didn't catch it. Are you connected?",
			script_path
		)
		_send_exercise_validated_signal(false)
		return
	_code_editor_is_dirty = false
	LiveEditorState.update_nodes(script, nodes_paths)
	_validation_manager.validate_all()
	var validation_errors: Array = yield(_validation_manager, "validation_completed_all")
	var validation_success = validation_errors.size() == 0
	_send_exercise_validated_signal(validation_success)


func _on_pause_button_pressed() -> void:
	_game_viewport.toggle_scene_pause()


func _on_code_editor_text_changed(_text: String) -> void:
	_code_editor_is_dirty = true


func _send_exercise_validated_signal(is_valid: bool) -> void:
	yield(get_tree(), "idle_frame")
	emit_signal("exercise_validated", is_valid)


func set_slice_properties(new_slice_properties: SliceProperties) -> void:
	if not new_slice_properties is SliceProperties:
		push_error("setting a scene that is invalid")
		return
	if slice_properties == new_slice_properties:
		return
	slice_properties = new_slice_properties


func get_slice_properties() -> SliceProperties:
	return slice_properties as SliceProperties


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	_lesson_panel.title = new_title


func set_goal(new_goal: String) -> void:
	goal = new_goal
	if not is_inside_tree():
		yield(self, "ready")
	_goal_rich_text_label.bbcode_text = goal


func set_progress(new_progress: float) -> void:
	progress = new_progress
	if not is_inside_tree():
		yield(self, "ready")
	_progress_bar.value = progress


func set_initial_editor_text(new_text: String) -> void:
	initial_editor_text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	if _code_editor:
		_code_editor.text = initial_editor_text


func get_initial_editor_text() -> String:
	if not is_inside_tree() or not _code_editor:
		return initial_editor_text
	return _code_editor.text
