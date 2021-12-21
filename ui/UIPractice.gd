tool
class_name UIPractice
extends Control

const PracticeHintScene := preload("components/PracticeHint.tscn")
const LessonDonePopupScene := preload("components/popups/LessonDonePopup.tscn")

export var test_practice: Resource

var progress := 0.0 setget set_progress

var _script_slice: SliceProperties
var _tester: PracticeTester
# If `true`, the text changed but was not saved.
var _code_editor_is_dirty := false
var _practice: Practice

onready var _game_container := find_node("Output") as PanelContainer
onready var _game_viewport := _game_container.find_node("GameViewport") as GameViewport
onready var _output_console := _game_container.find_node("Console") as OutputConsole

onready var _practice_info_panel := find_node("PracticeInfoPanel") as PracticeInfoPanel
onready var _documentation_panel := find_node("DocumentationPanel") as RichTextLabel
onready var _hints_container := _practice_info_panel.hints_container

onready var _code_editor := find_node("CodeEditor") as CodeEditor


func _ready() -> void:
	randomize()
	if Engine.editor_hint:
		return

	_code_editor.connect("action", self, "_on_code_editor_button")
	_code_editor.connect("text_changed", self, "_on_code_editor_text_changed")

	if test_practice and get_parent() == get_tree().root:
		setup(test_practice)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_distraction_free_mode"):
		var is_distraction_free := not _practice_info_panel.visible
		_practice_info_panel.visible = is_distraction_free
		_game_container.visible = is_distraction_free


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == BUTTON_LEFT and mb.pressed and get_focus_owner():
		get_focus_owner().release_focus()


func setup(practice: Practice) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_practice = practice
	_practice_info_panel.goal_rich_text_label.bbcode_text = practice.goal
	_practice_info_panel.title_label.text = practice.title
	_code_editor.text = practice.starting_code

	_hints_container.visible = not practice.hints.empty()
	var index := 0
	var available_width := _hints_container.rect_size.x - _hints_container.padding
	for hint in practice.hints:
		var practice_hint: PracticeHint = PracticeHintScene.instance()
		practice_hint.title = "Hint " + String(index + 1).pad_zeros(1)
		practice_hint.bbcode_text = hint
		_hints_container.add_child(practice_hint)
		practice_hint.rect_min_size.x = available_width

	var slice_path := practice.script_slice_path
	var base_directory := practice.resource_path.get_base_dir()
	if slice_path.is_rel_path():
		slice_path = base_directory.plus_file(slice_path)
	_script_slice = load(slice_path)

	var validator_path := practice.validator_script_path
	if validator_path.is_rel_path():
		validator_path = base_directory.plus_file(validator_path)
	_tester = (load(validator_path) as GDScript).new()
	_tester.setup(_game_viewport.get_child(0), _script_slice)

	var documentation_bbcode := _practice.get_documentation_as_bbcode()
	if documentation_bbcode == "":
		# We assume the panel is a direct child of a Revealer
		var _documentation_panel_revealer = _documentation_panel.get_parent() as Revealer
		_documentation_panel_revealer.hide()
	else:
		_documentation_panel.bbcode_text = documentation_bbcode

	_practice_info_panel.display_tests(_tester.get_test_names())
	LiveEditorState.current_slice = _script_slice
	_game_viewport.use_scene()


func set_progress(new_progress: float) -> void:
	progress = new_progress
	if not is_inside_tree():
		yield(self, "ready")
	_practice_info_panel.progress_bar.value = progress


func _on_run_button_pressed() -> void:
	_output_console.clear_messages()

	_script_slice.current_text = _code_editor.get_text()
	var script_file_name: String = _script_slice.get_script_properties().file_name
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
				script_file_name,
				error.error_range.start.line,
				error.error_range.start.character,
				error.code
			)
		return

	script_text = LiveEditorMessageBus.replace_script(script_file_name, script_text)
	var script = GDScript.new()
	script.source_code = script_text

	var script_is_valid = script.reload()
	if script_is_valid != OK:
		LiveEditorMessageBus.print_error(
			"The script has an error, but the language server didn't catch it. Are you connected?",
			script_file_name
		)
		return

	_code_editor_is_dirty = false
	LiveEditorState.update_nodes(script, nodes_paths)

	var result := _tester.run_tests()
	_practice_info_panel.update_tests_display(result)
	if result.is_success():
		var popup := LessonDonePopupScene.instance()
		add_child(popup)
		popup.connect("pressed", Events, "emit_signal", ["practice_completed", _practice])


func _on_code_editor_text_changed(_text: String) -> void:
	_code_editor_is_dirty = true


func _on_code_editor_button(which: String) -> void:
	match which:
		_code_editor.ACTIONS.RUN:
			_on_run_button_pressed()
		_code_editor.ACTIONS.PAUSE:
			_game_viewport.toggle_scene_pause()
