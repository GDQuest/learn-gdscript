tool
class_name UIPractice
extends Control

const RevealerScene := preload("components/Revealer.tscn")

var progress := 0.0 setget set_progress

var _script_slice: SliceProperties
var _tester: PracticeTester
# If `true`, the text changed but was not saved.
var _code_editor_is_dirty := false
var _practice: Practice

onready var _game_container := find_node("Output") as PanelContainer
onready var _game_viewport := _game_container.find_node("GameViewport") as GameViewport

onready var _practice_info_panel := find_node("PracticeInfoPanel") as PracticeInfoPanel
onready var _hints_container := _practice_info_panel.hints_container

onready var _code_editor := find_node("CodeEditor") as CodeEditor


func _ready() -> void:
	randomize()
	if Engine.editor_hint:
		return

	_code_editor.connect("action", self, "_on_code_editor_button")
	_code_editor.connect("text_changed", self, "_on_code_editor_text_changed")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_distraction_free_mode"):
		var is_distraction_free := not _practice_info_panel.visible
		_practice_info_panel.visible = is_distraction_free
		_game_container.visible = is_distraction_free


func setup(practice: Practice) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_practice = practice
	_practice_info_panel.goal_rich_text_label.bbcode_text = practice.goal
	_practice_info_panel.title_label.text = practice.title
	_code_editor.text = practice.starting_code

	_hints_container.visible = practice.hints.empty()
	var index := 0
	for hint in practice.hints:
		var revealer: Revealer = RevealerScene.instance()
		revealer.title = "Hint " + String(index + 1).pad_zeros(1)

		_hints_container.add_child(revealer)

		var label := Label.new()
		label.text = hint
		revealer.add_child(label)
		revealer.is_expanded = false

		revealer.rect_min_size.x = _hints_container.rect_size.x - _hints_container.padding

	_script_slice = load(practice.script_slice_path)
	LiveEditorState.current_slice = _script_slice
	_game_viewport.use_scene()

	_tester = load(practice.validator_script_path).new()
	_tester.setup(_game_viewport, _script_slice)
	_practice_info_panel.display_tests(_tester.get_test_names())


func set_progress(new_progress: float) -> void:
	progress = new_progress
	if not is_inside_tree():
		yield(self, "ready")
	_practice_info_panel.progress_bar.value = progress


func _on_save_button_pressed() -> void:
	var script_path: String = _script_slice.get_script_properties().file_path
	var script_text: String = _script_slice.current_full_text
	var nodes_paths: Array = _script_slice.get_script_properties().nodes_paths
	var verifier := ScriptVerifier.new(self, script_text)
	verifier.test()
	var errors: Array = yield(verifier, "errors")
	if not errors.empty():
		_code_editor.slice_editor.errors = errors
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
	var script_is_valid = script.reload()
	if script_is_valid != OK:
		LiveEditorMessageBus.print_error(
			"The script has an error, but the language server didn't catch it. Are you connected?",
			script_path
		)
		return
	_code_editor_is_dirty = false
	LiveEditorState.update_nodes(script, nodes_paths)

	var result := _tester.run_tests()
	_practice_info_panel.update_tests_display(result)
	if result.is_success():
		Events.emit_signal("practice_completed", _practice)


func _on_code_editor_text_changed(_text: String) -> void:
	_code_editor_is_dirty = true


func _on_code_editor_button(which: String) -> void:
	match which:
		_code_editor.ACTIONS.SAVE:
			_on_save_button_pressed()
		_code_editor.ACTIONS.PAUSE:
			_game_viewport.toggle_scene_pause()
