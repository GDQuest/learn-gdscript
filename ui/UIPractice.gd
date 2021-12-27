tool
class_name UIPractice
extends Control

const PracticeHintScene := preload("components/PracticeHint.tscn")
const LessonDonePopupScene := preload("components/popups/LessonDonePopup.tscn")

export var test_practice: Resource

var _script_slice: SliceProperties
var _tester: PracticeTester
# If `true`, the text changed but was not saved.
var _code_editor_is_dirty := false
var _practice: Practice

var _is_left_panel_open := true
var _info_panel_start_width := -1.0

onready var _output_container := find_node("Output") as Control
onready var _game_container := find_node("GameContainer") as Container
onready var _game_viewport := _output_container.find_node("GameViewport") as GameViewport
onready var _output_console := _output_container.find_node("Console") as OutputConsole

onready var _info_panel := find_node("PracticeInfoPanel") as PracticeInfoPanel
onready var _documentation_panel := find_node("DocumentationPanel") as RichTextLabel
onready var _hints_container := _info_panel.hints_container

onready var _code_editor := find_node("CodeEditor") as CodeEditor

onready var _info_panel_control := $Margin/Layout/Control as Control
onready var _tween := $Tween as Tween


func _ready() -> void:
	randomize()
	if Engine.editor_hint:
		return

	_code_editor.connect("action", self, "_on_code_editor_button")
	_code_editor.connect("text_changed", self, "_on_code_editor_text_changed")
	_code_editor.connect("console_toggled", self, "_on_console_toggled")
	_output_console.connect("reference_clicked", self, "_on_code_reference_clicked")

	if test_practice and get_parent() == get_tree().root:
		setup(test_practice, null)

	_info_panel_start_width = _info_panel.rect_size.x


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_distraction_free_mode"):
		_toggle_distraction_free_mode()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == BUTTON_LEFT and mb.pressed and get_focus_owner():
		# Makes clicks on the empty area to remove focus from various controls, specifically
		# the code editor.
		get_focus_owner().release_focus()


func setup(practice: Practice, _course: Course) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_practice = practice
	_info_panel.goal_rich_text_label.bbcode_text = TextUtils.bbcode_add_code_color(practice.goal)
	_info_panel.title_label.text = practice.title
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
		index += 1

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

	var documentation_reference := _practice.get_documentation_raw()
	if documentation_reference.is_empty():
		_info_panel.clear_documentation()
	else:
		_info_panel.set_documentation(documentation_reference)

	_info_panel.display_tests(_tester.get_test_names())
	LiveEditorState.current_slice = _script_slice
	_game_viewport.use_scene()


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
	_info_panel.update_tests_display(result)
	if result.is_success():
		var popup := LessonDonePopupScene.instance()
		add_child(popup)
		popup.fade_in(_game_container)
		popup.connect("accepted", self, "_on_practice_popup_accepted")


func _toggle_distraction_free_mode() -> void:
	_is_left_panel_open = not _is_left_panel_open
	_tween.stop_all()
	var duration := 0.5
	if _is_left_panel_open:
		_tween.interpolate_property(_info_panel_control, "rect_min_size:x", _info_panel_control.rect_min_size.x, _info_panel_start_width, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		_tween.interpolate_property(_info_panel_control, "modulate:a", _info_panel_control.modulate.a, 1.0, duration)
	else:
		_tween.interpolate_property(_info_panel_control, "rect_min_size:x", _info_panel_control.rect_min_size.x, 0.0, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		_tween.interpolate_property(_info_panel_control, "modulate:a", _info_panel_control.modulate.a, 0.0, duration - 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.15)
	_tween.start()

	_code_editor.set_distraction_free_state(not _is_left_panel_open)


func _on_code_editor_text_changed(_text: String) -> void:
	_code_editor_is_dirty = true


func _on_code_editor_button(which: String) -> void:
	match which:
		_code_editor.ACTIONS.RUN:
			_on_run_button_pressed()
		_code_editor.ACTIONS.PAUSE:
			_game_viewport.toggle_scene_pause()
		_code_editor.ACTIONS.DFMODE:
			_toggle_distraction_free_mode()


func _on_console_toggled() -> void:
	_output_console.visible = not _output_console.visible


func _on_code_reference_clicked(_file_name: String, line: int, character: int) -> void:
	_code_editor.slice_editor.highlight_line(line, character)


func _on_practice_popup_accepted() -> void:
	Events.emit_signal("practice_completed", _practice)
