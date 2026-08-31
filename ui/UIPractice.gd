@tool
class_name UIPractice
extends UINavigatablePage

signal test_student_code_completed

const RUN_AUTOTIMER_DURATION := 5.0
const SLIDE_TRANSITION_DURATION := 0.5
## Maximum allowed iterations in loops to prevent infinite loops. Keep this
## number low to avoid big slowdowns if the student calls print() e.g. in a
## nested loop.
const MAX_LOOP_ITERATIONS := 100

const PracticeHintScene := preload("screens/practice/PracticeHint.tscn")
const PracticeListPopup := preload("components/popups/PracticeListPopup.gd")
const PracticeDonePopup := preload("components/popups/PracticeDonePopup.gd")
const PracticeLeaveUnfinishedPopup := preload("components/popups/PracticeLeaveUnfinishedPopup.gd")
const documentation_resource: Documentation = preload("res://course/Documentation.tres")

const BENIGN_CACHE_ERROR := 'Error while getting cache for script "".'

static var REGEX_DIVSION_BY_ZERO := RegEx.create_from_string((r"[/%] *0"))
static var REGEX_CLASS_NAME := RegEx.create_from_string(r"\s*class_name\s")
static var REGEX_TOP_ANNOTATION := RegEx.create_from_string(r"\s*@")

@export var lesson_test_practice: String
@export_range(0, 1, 1, "or_greater") var test_practice: int
var _practice: BBCodeParser.ParseNode
var _practice_completed := false
var _practice_solution_used := false
var _lesson_number := 0
var _practice_index := 0
var _is_last_practice := false

var _script_slice: ScriptSlice:
	set = _set_script_slice
var _tester: PracticeTester
## For integration tests: Saves the result of the last ran practice validator so
## integration tests can capture and report the exact failed checks after the UI
## has finished updating.
var last_test_result: PracticeTester.TestResult
# If `true`, the text changed but was not saved.
var _code_editor_is_dirty := false

# Set to true when running the test scene, then to false the moment Events.practice_run_completed emits.
var _run_tests_requested := false
# Auto-timer forces Events.practice_run_completed after a fixed duration to fallback
# if practice code doesn't emit on its own
var _run_autotimer: Timer

var _is_info_panel_open := true
var _is_solution_panel_open := false

var _current_scene: Node
# Used to automate resetting transform and visibility to default in case the
# student calls hide(), changes transform, etc. in their practice code.
var _current_scene_reset_values := { &"visible": null, &"transform": null }

var _scene_tween: Tween

@onready var _layout_container: HBoxContainer = %LayoutContainer
@onready var _game_container: Container = %GameContainer
@onready var _game_view: GameView = %GameView
@onready var _output_console: OutputConsole = %Console
@onready var _output_anchors: Control = %OutputAnchors
@onready var _solution_panel: Control = %SolutionContainer
@onready var _use_solution_button: Button = %UseSolutionButton
@onready var _info_panel_anchors: Control = %InfoPanelAnchors
@onready var _info_panel: PracticeInfoPanel = %PracticeInfoPanel
@onready var _hints_container: Revealer = _info_panel.hints_container
@onready var _practice_list: PracticeListPopup = %PracticeListPopup
@onready var _practice_done_popup: PracticeDonePopup = %PracticeDonePopup
@onready var _practice_leave_unfinished_popup: PracticeLeaveUnfinishedPopup = %PracticeLeaveUnfinishedPopup
@onready var _code_editor: CodeEditor = %CodeEditor
@onready var _solution_editor: SliceEditor = %SolutionEditor


func _init():
	REGEX_DIVSION_BY_ZERO.compile("[/%] *0")

	_run_autotimer = Timer.new()
	_run_autotimer.one_shot = true
	_run_autotimer.wait_time = RUN_AUTOTIMER_DURATION
	add_child(_run_autotimer)

	_run_autotimer.timeout.connect(_on_autotimer_timeout)

	_on_init_set_javascript()


func _ready() -> void:
	super._ready()

	randomize()
	if Engine.is_editor_hint():
		return

	_code_editor.action_taken.connect(_on_code_editor_action_taken)
	_code_editor.text_changed.connect(_on_code_editor_text_changed)
	_code_editor.console_toggled.connect(_on_console_toggled)
	_output_console.reference_clicked.connect(_on_code_reference_clicked)
	_use_solution_button.pressed.connect(_on_use_solution_pressed)

	_info_panel.list_requested.connect(_on_list_requested)

	_practice_done_popup.accepted.connect(_on_next_requested)

	_practice_leave_unfinished_popup.confirmed.connect(_accept_unload)
	_practice_leave_unfinished_popup.denied.connect(_deny_unload)

	Events.practice_run_completed.connect(_test_student_code)
	TranslationManager.translation_changed.connect(_on_translation_changed)

	_update_slidable_panels()
	_layout_container.resized.connect(_update_slidable_panels)

	_solution_panel.modulate.a = 0.0
	_solution_panel.offset_left = _output_anchors.size.x

	if lesson_test_practice and get_parent() == get_tree().root:
		var course_index: CourseIndex = CourseIndexPaths.get_course_index_instance()
		var lesson := NavigationManager.get_navigation_resource(lesson_test_practice)
		var practice := BBCodeUtils.get_lesson_practice(lesson, test_practice)
		var lesson_number := course_index.get_lesson_number(lesson.bbcode_path)
		setup(practice, lesson, course_index, lesson_number)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_slidable_panels()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if (
		mb and mb.button_index == MOUSE_BUTTON_LEFT
		and mb.pressed and get_viewport().gui_get_focus_owner()
	):
		# Makes clicks on the empty area to remove focus from various controls, specifically
		# the code editor.
		get_viewport().gui_get_focus_owner().release_focus()


func setup(
	practice: BBCodeParser.ParseNode,
	lesson: BBCodeParser.ParseNode,
	course_index: CourseIndex,
	lesson_number: int,
) -> void:
	if not is_inside_tree():
		await self.ready

	_practice = practice
	_practice_completed = false
	_practice_solution_used = false
	_lesson_number = lesson_number
	var lesson_info := course_index.get_lesson_info(lesson.bbcode_path)
	var practice_info := course_index.get_practice_info(
		lesson.bbcode_path,
		BBCodeUtils.get_practice_id(practice),
	)
	_practice_index = practice_info.index
	_is_last_practice = _practice_index >= lesson_info.practices.size() - 1
	_practice_done_popup.do_fade_background_on_exit = not _is_last_practice

	var starting_code := BBCodeUtils.get_practice_starting_code(practice)
	_code_editor.text = starting_code
	var starting_position := BBCodeUtils.get_practice_cursor(practice)
	_code_editor.update_cursor_position(starting_position.x, starting_position.y)

	var hints := BBCodeUtils.get_practice_hints(practice)
	_hints_container.visible = not hints.is_empty()
	for _i in hints.size():
		var practice_hint: PracticeHint = PracticeHintScene.instantiate()
		_hints_container.add_child(practice_hint)
	_update_practice_metadata()

	var base_directory := practice.bbcode_path.get_base_dir()

	var script_path := BBCodeUtils.get_practice_script_slice_path(practice)
	if script_path.is_relative_path():
		script_path = base_directory.path_join(script_path)
	if not script_path.begins_with("res://"):
		script_path = "res://" + script_path
	var slice_name := BBCodeUtils.get_practice_script_slice_name(practice)
	var slice := SliceParser.load_from_script(script_path, slice_name)
	if not slice:
		push_error("Failed to load script slice from: " + script_path)
		return
	_set_script_slice(slice)
	_code_editor.slice_editor.setup(_script_slice)
	_code_editor.set_continue_allowed(false)

	_solution_editor.text = _script_slice.slice_text

	var validator_path := BBCodeUtils.get_practice_validator_path(practice)
	if validator_path.is_relative_path():
		validator_path = base_directory.path_join(validator_path)
	_tester = (load(validator_path) as GDScript).new()
	_tester.setup(_game_view.get_viewport_override(), _script_slice)

	var documentation_tags := BBCodeUtils.get_practice_documentation(practice)
	var documentation_reference := documentation_resource.get_references(documentation_tags)
	if documentation_reference.is_empty():
		_info_panel.clear_documentation()
	else:
		_info_panel.set_documentation(documentation_reference)

	_info_panel.display_tests(_tester.get_test_names())
	_game_view.use_scene(_current_scene, _script_slice.get_viewport_size())

	# In case we directly test a practice from the editor, we don't have access to the lesson.
	if lesson and course_index:
		_practice_list.clear_items()
		var practice_id := BBCodeUtils.get_practice_id(practice)
		for i in lesson_info.practices.size():
			var practice_data := BBCodeUtils.get_lesson_practice(lesson, i)
			_practice_list.add_item(
				practice_data,
				lesson,
				course_index,
				lesson_number,
				BBCodeUtils.get_practice_id(practice_data) == practice_id,
			)

		var user_profile := UserProfiles.get_profile()
		var completed_before = user_profile.is_lesson_practice_completed(
			course_index.get_course_id(),
			lesson.bbcode_path,
			practice_id,
		)
		if completed_before:
			_info_panel.set_status_icon(_info_panel.Status.COMPLETED_BEFORE)


# Turns off animations to run integration tests faster.
func turn_on_test_mode() -> void:
	_info_panel.skip_animations = true


func _update_labels() -> void:
	if not _practice:
		return

	_update_practice_metadata()
	_info_panel.display_tests(_tester.get_test_names())


func _on_translation_changed() -> void:
	# Note: Nathan: defensive checks are for things like automated tests and
	# debugging. Though I think we need to refactor this at some point so any
	# testing or instrumentation all consistently has correctly set up state.
	if not _practice:
		return

	if not NavigationManager.current_url.is_empty():
		var lesson := NavigationManager.get_navigation_resource(_practice.bbcode_path)
		if lesson:
			_practice = BBCodeUtils.get_lesson_practice(lesson, _practice_index)

	_update_labels()


func _update_practice_metadata() -> void:
	if not _practice:
		return

	var rtl := TranslationManager.current_translation_is_rtl()

	var title := BBCodeUtils.get_practice_title(_practice)
	_info_panel.title_label.text = "L%d.P%d %s" % [
		_lesson_number,
		_practice_index + 1,
		tr(title).capitalize(),
	]
	_info_panel.title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
	var goal := BBCodeUtils.get_practice_goal(_practice)
	_info_panel.goal_rich_text_label.text = TextUtils.bbcode_add_code_color(
		TextUtils.paragraph(TextUtils.tr_paragraph(goal)),
	)
	_info_panel.goal_rich_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT

	var index := 0
	var hints := BBCodeUtils.get_practice_hints(_practice)
	for child_node in _hints_container.get_children():
		var practice_hint := child_node as PracticeHint
		if not practice_hint:
			continue

		practice_hint.title = tr("Hint %s") % [str(index + 1).pad_zeros(1)]
		practice_hint.set_text_alignment(
			HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
		)
		practice_hint.text = TextUtils.tr_paragraph(hints[index])
		index += 1


func get_screen_resource() -> BBCodeParser.ParseNode:
	return _practice


## Returns the code currently entered by the student in the practice editor.
func get_user_code() -> String:
	return _code_editor.get_text()


func _set_script_slice(new_slice: ScriptSlice) -> void:
	if new_slice == _script_slice:
		return
	_script_slice = new_slice
	_output_console.setup(_script_slice)

	var scene := _script_slice.get_scene()
	if not scene:
		push_error("Failed to load scene for script: " + _script_slice.script_path)
		return
	_current_scene = scene.instantiate()
	_current_scene_reset_values.visible = _current_scene.get("visible")
	_current_scene_reset_values.transform = _current_scene.get("transform")


func _validate_and_run_student_code() -> void:
	# Prepare everything for testing user code.
	_game_view.paused = false

	_code_editor.lock_editor()
	_code_editor.set_pause_button_pressed(false)
	_code_editor.set_locked_message(tr("Validating Your Code..."))
	_hide_solution_panel()
	_code_editor.set_solution_button_pressed(false)

	_output_console.clear_messages()
	_info_panel.reset_tests_status()

	_disable_distraction_free_mode()

	# Complete the script from the slice and the base script.
	_script_slice.current_text = _code_editor.get_text()
	var script_text := _script_slice.get_current_full_text()
	var script_file_name := _script_slice.get_script_file_name()

	# Mixed indentation is an error we cannot catch from the GDScript parser in
	# some situations, so we manually look for it to help students understand the error.
	var mixed_indent_error_line := _check_for_mixed_indentation(script_text)
	if mixed_indent_error_line != -1:
		var error := ScriptError.new()
		error.message = "Parse error: Spaces used before tabs on a line"
		error.severity = 1
		error.code = GDScriptCodes.ErrorCode.SPACES_BEFORE_TABS
		error.error_range.start.line = mixed_indent_error_line
		error.error_range.start.character = 0
		MessageBus.print_script_error(error, script_file_name)
		_code_editor.unlock_editor()
		return

	var verifier_script := script_text
	var script_is_desynced_by_one_line := false

	if not _has_class_name(verifier_script):
		# GDScriptAnalyzer needs a path or class_name. As we're feeding code directly into the parser,
		# we can't really have a path, so we need a class_name to fool it
		var initial_insertion_character := _find_first_non_annotation_entry_point(verifier_script)
		verifier_script = verifier_script.insert(
			initial_insertion_character,
			"class_name TEMP_UserScript\n",
		)
		script_is_desynced_by_one_line = true

	var verifier := OfflineScriptVerifier.new(verifier_script)

	# Do local sanity checks for the script.
	var analyzer := GDScriptASTAnalyzer.new(verifier.get_class_ast() as GDClassNode)

	# Check for recursive functions
	var recursive_function := analyzer.find_any_recursive_function()
	if recursive_function != "":
		var error := ScriptError.new()
		error.message = (
			tr("The function '%s' calls itself, this creates an infinite loop")
			% [recursive_function]
		)
		error.severity = 1
		error.code = GDQuestCodes.ErrorCode.RECURSIVE_FUNCTION
		MessageBus.print_script_error(error, script_file_name)
		_code_editor.unlock_editor()
		return
	var ast_analysis_result := analyzer.analyze_ast()
	if ast_analysis_result.has_infinite_loop:
		var error := ScriptError.new()
		error.message = tr(
			"You have a loop that runs forever without a break statement. This would freeze the app.",
		)
		error.severity = 1
		error.code = GDQuestCodes.ErrorCode.INFINITE_WHILE_LOOP
		MessageBus.print_script_error(error, script_file_name)
		_code_editor.unlock_editor()
		return

	verifier.test()
	var errors := verifier.errors

	if not errors.is_empty():
		# GDScriptAnalyzer will complain the first time it parses the script from the verifier
		# so we capture it here to ignore
		for i in range(errors.size() - 1, -1, -1):
			var error: ScriptError = errors[i]
			if error.message == BENIGN_CACHE_ERROR:
				errors.remove_at(i)

	if not errors.is_empty():
		if script_is_desynced_by_one_line:
			for error: ScriptError in errors:
				error.error_range.start.line -= 1
				error.error_range.end.line -= 1
		_code_editor.slice_editor.errors = errors

		for index in errors.size():
			var gdscript_ast_root := verifier.get_class_ast() as GDClassNode
			var error: ScriptError = errors[index]

			MessageBus.print_script_error(error, script_file_name)

			var typo_result := GDScriptCodes.parse_typo_error_message(error.message)
			if typo_result != null:
				var best_match := _search_for_similar_identifier(
					typo_result.identifier,
					typo_result.is_function,
					gdscript_ast_root,
					typo_result.base,
				)
				if best_match != "":
					MessageBus.print_warning(
						tr("You typed \"%s\"; did you mean \"%s\"?")
						% [typo_result.identifier, best_match],
						"",
					)


		var is_missing_parser_error: bool = (
			errors.size() == 1
			and OfflineScriptVerifier.check_error_is_missing_parser_error(errors[0] as ScriptError)
		)

		if not is_missing_parser_error:
			_code_editor.unlock_editor()
			return

	# Run student code
	# Generate a runnable script, check for uncaught errors.
	_code_editor.set_locked_message(tr("Running Your Code..."))
	await get_tree().process_frame

	script_text = MessageBus.replace_print_calls_in_script(script_file_name, script_text)

	var lines_loop_start := ast_analysis_result.lines_loop_start
	if script_is_desynced_by_one_line:
		for index in lines_loop_start.size():
			lines_loop_start[index] -= 1
	script_text = _add_counters_to_loops(script_text, lines_loop_start)
	if REGEX_DIVSION_BY_ZERO.search(script_text):
		var error := ScriptError.new()
		error.message = tr(
			'There is a division by zero in your code. You cannot divide by zero in code. Please ensure you have no "/ 0" or "% 0" in your code.',
		)
		error.severity = 1
		error.code = GDQuestCodes.ErrorCode.INVALID_NO_CATCH
		MessageBus.print_script_error(error, script_file_name)
		_code_editor.unlock_editor()
		return

	var script := GDScript.new()
	script.source_code = script_text

	var script_is_valid = script.reload()
	if script_is_valid != OK:
		var error := ScriptError.new()
		error.message = tr(
			"Oh no! The script has an error (code %s), but the Script Verifier did not catch it"
			% script_is_valid,
		)
		error.severity = 1
		error.code = GDQuestCodes.ErrorCode.INVALID_NO_CATCH
		MessageBus.print_script_error(error, script_file_name)
		_code_editor.unlock_editor()
		return

	_code_editor_is_dirty = false

	# Start the auto-timer used to perform tests in case the scene doesn't emit the required signal.
	_run_tests_requested = true
	_run_autotimer.start()
	# Reset and run the test scene.
	# TODO: node_paths is a leftover from an older prototype where we had the ability
	# to navigate and edit multiple scripts, so we needed to be able to update multiple
	# nodes potentially. This could now be removed.
	var nodes_paths := [NodePath("")]
	_update_nodes(script, nodes_paths)


## Compares the provided identifier to members in the root symbols, and whatever ClassDB can dredge up
## from the base class, plus the @GlobalScope and @GDscript builtins.
## If similar enough (>=80% confidence) it provides the best match it found. If too low it returns an empty string.
func _search_for_similar_identifier(
	identifier: String,
	is_function: bool,
	root: GDClassNode,
	base: String,
) -> String:
	var target_members := root.get_members().filter(
		func(member: GDMember) -> bool:
			if is_function:
				return member.get_type() == GDMember.Type.FUNCTION
			return member.get_type() != GDMember.Type.FUNCTION,
	)

	var members := []
	if base == "self":
		@warning_ignore("incompatible_ternary")
		target_members.map(
			func(member: GDMember) -> String:
				return member.get_as_function_node().get_identifier().name if is_function else member.get_name(),
		)

	members.append_array(BuiltIns.BUILTIN_METHODS if is_function else BuiltIns.BUILTINT_PROPS)

	if base == "self":
		var extend_array := root.get_extends()
		if extend_array:
			@warning_ignore("unsafe_method_access")
			base = extend_array.front().get_name()

	if base != "self":
		if ClassDB.class_exists(base):
			var base_member_list := ClassDB.class_get_method_list(base) if is_function else ClassDB.class_get_property_list(
				base
			)
			var base_members := base_member_list.map(
				func(member_data: Dictionary) -> String:
					return member_data.name,
			)
			members.append_array(base_members)
		else:
			var globals := ProjectSettings.get_global_class_list()
			var target_base_idx := globals.find_custom(
				func(cls: Dictionary) -> bool:
					return cls.class == base,
			)
			if target_base_idx >= -1:
				var parent_class: Dictionary = globals[target_base_idx]
				var parent_script := load(parent_class.path) as Script
				if parent_script:
					var base_member_list := (
						parent_script.get_script_method_list() + parent_script.get_method_list()
						if is_function
						else parent_script.get_script_property_list()
						+ parent_script.get_property_list()
					)
					var base_members := base_member_list.map(
						func(member_data: Dictionary) -> String:
							return member_data.name,
					)
					members.append_array(base_members)

	var best_similarity := 0.0
	var best_match := ""
	for member: String in members:
		var similarity := member.similarity(identifier)
		if similarity > best_similarity:
			best_match = member
			best_similarity = similarity
	return best_match if best_similarity >= 0.8 else ""


## Updates the source code by adding counters that force the loop to break in
## case we reach the maximum allowed iteration count.
static func _add_counters_to_loops(script_text: String, lines_loop_start: Array[int]) -> String:
	var modified_code := PackedStringArray()
	var current_loop_index := 0
	var lines := script_text.split("\n")
	for current_line_index in lines.size():
		var line: String = lines[current_line_index]
		if not lines_loop_start.has(current_line_index + 1):
			modified_code.append(line)
			continue

		var indent := line.length() - line.lstrip("\t").length()
		var tabs := "\t".repeat(indent)
		var guard_counter_varname := "__gdquest_loop_guard_" + str(current_loop_index)
		current_loop_index += 1
		modified_code.append(tabs + "var " + guard_counter_varname + " := 0")
		modified_code.append(line)
		modified_code.append(tabs + "\t" + guard_counter_varname + " += 1")
		modified_code.append(
			tabs + "\tif " + guard_counter_varname + " >= %s:" % MAX_LOOP_ITERATIONS,
		)
		modified_code.append(tabs + "\t\tbreak")
	return "\n".join(modified_code)


func _test_student_code() -> void:
	if not _run_tests_requested:
		return
	_run_tests_requested = false

	var script_file_name := _script_slice.get_script_file_name()

	# Run tests on the scene.
	_code_editor.set_locked_message(tr("Running Tests..."))
	_info_panel.set_tests_pending()

	var result := _tester.run_tests()
	last_test_result = result
	_info_panel.set_tests_status(result, script_file_name)
	await _info_panel.tests_updated

	# Show the end of practice popup.
	if not _practice_completed and result.is_success():
		_practice_completed = true

		if not _practice_solution_used:
			Events.practice_completed.emit(_practice)

		_practice_done_popup.show()
		_practice_done_popup.fade_in(_game_container)

	# Clean-up.
	_cleanup_post_test()


func _cleanup_post_test() -> void:
	_code_editor.unlock_editor()
	if _practice_completed:
		_code_editor.set_continue_allowed(true)

	test_student_code_completed.emit()


func _reset_practice() -> void:
	# Code is already reset by the slice editor.
	_info_panel.reset_tests_status()
	_code_editor.slice_editor.errors = []
	_output_console.clear_messages()

	if _current_scene.has_method("reset"):
		_current_scene.call("reset")
		for property: StringName in _current_scene_reset_values:
			_current_scene.set(property, _current_scene_reset_values[property])


func _update_slidable_panels() -> void:
	# Wait a frame to make sure the new size has been applied.
	await get_tree().process_frame

	# We use _output_anchors for reference because it never leaves the screen, so we can rely on it
	# to always report the target size for one third of the hbox.

	# Update info panel.
	_info_panel.custom_minimum_size = Vector2(_output_anchors.size.x, 0)
	_info_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE,
	)

	# Update solution panel.
	_solution_panel.custom_minimum_size = Vector2(_output_anchors.size.x, 0)
	_solution_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE,
	)
	if not _is_solution_panel_open:
		_solution_panel.offset_left = _output_anchors.size.x


func _toggle_distraction_free_mode() -> void:
	if _is_info_panel_open:
		_enable_distraction_free_mode()
	else:
		_disable_distraction_free_mode()


func _disable_distraction_free_mode() -> void:
	_is_info_panel_open = true
	if _scene_tween:
		_scene_tween.kill()

	_scene_tween = create_tween().set_parallel()
	_scene_tween \
			.tween_property(
		_info_panel_anchors,
		"size_flags_stretch_ratio",
		1.0,
		SLIDE_TRANSITION_DURATION,
	) \
			.from(_info_panel_anchors.size_flags_stretch_ratio) \
			.set_trans(Tween.TRANS_SINE)
	_scene_tween \
			.tween_property(
		_code_editor,
		"size_flags_stretch_ratio",
		1.0,
		SLIDE_TRANSITION_DURATION,
	) \
			.from(_code_editor.size_flags_stretch_ratio) \
			.set_trans(Tween.TRANS_SINE)
	_scene_tween \
			.tween_property(_info_panel_anchors, "modulate:a", 1.0, SLIDE_TRANSITION_DURATION) \
			.from(_info_panel_anchors.modulate.a) \
			.set_ease(Tween.EASE_IN)

	_code_editor.set_distraction_free_state(not _is_info_panel_open)


func _enable_distraction_free_mode() -> void:
	_update_slidable_panels()

	_is_info_panel_open = false
	if _scene_tween:
		_scene_tween.kill()
	_scene_tween = create_tween().set_parallel()

	_scene_tween \
			.tween_property(
		_info_panel_anchors,
		"size_flags_stretch_ratio",
		0.0,
		SLIDE_TRANSITION_DURATION,
	) \
			.from(_info_panel_anchors.size_flags_stretch_ratio) \
			.set_trans(Tween.TRANS_SINE)
	_scene_tween \
			.tween_property(
		_code_editor,
		"size_flags_stretch_ratio",
		2.0,
		SLIDE_TRANSITION_DURATION,
	) \
			.from(_code_editor.size_flags_stretch_ratio) \
			.set_trans(Tween.TRANS_SINE)
	_scene_tween \
			.tween_property(
		_info_panel_anchors,
		"modulate:a",
		0.0,
		SLIDE_TRANSITION_DURATION - 0.25,
	) \
			.from(_info_panel_anchors.modulate.a) \
			.set_ease(Tween.EASE_IN) \
			.set_delay(0.15)

	_code_editor.set_distraction_free_state(not _is_info_panel_open)


func _toggle_solution_panel() -> void:
	if _is_solution_panel_open:
		_hide_solution_panel()
	else:
		_show_solution_panel()


func _show_solution_panel() -> void:
	_update_slidable_panels()

	_is_solution_panel_open = true
	if _scene_tween:
		_scene_tween.kill()
	_scene_tween = create_tween().set_parallel()

	_scene_tween \
			.tween_property(_solution_panel, "offset_left", 0.0, SLIDE_TRANSITION_DURATION) \
			.from(_solution_panel.offset_left) \
			.set_trans(Tween.TRANS_SINE)
	_scene_tween \
			.tween_property(_solution_panel, "modulate:a", 1.0, SLIDE_TRANSITION_DURATION) \
			.from(_solution_panel.modulate.a) \
			.set_ease(Tween.EASE_IN)


func _hide_solution_panel() -> void:
	_update_slidable_panels()

	_is_solution_panel_open = false
	if _scene_tween:
		_scene_tween.kill()
	_scene_tween = create_tween().set_parallel()

	_scene_tween \
			.tween_property(
		_solution_panel,
		"offset_left",
		_output_anchors.size.x,
		SLIDE_TRANSITION_DURATION,
	) \
			.from(_solution_panel.offset_left) \
			.set_trans(Tween.TRANS_SINE)
	_scene_tween \
			.tween_property(_solution_panel, "modulate:a", 0.0, SLIDE_TRANSITION_DURATION - 0.25) \
			.from(_solution_panel.modulate.a) \
			.set_ease(Tween.EASE_IN) \
			.set_delay(0.15)


func _on_use_solution_pressed() -> void:
	_code_editor.slice_editor.sync_text_with_slice()

	_practice_solution_used = true
	_info_panel.set_status_icon(_info_panel.Status.SOLUTION_USED)

	_hide_solution_panel()
	_code_editor.set_solution_button_pressed(false)
	_code_editor.set_restore_allowed(true)
	_update_game_paused()


func _update_game_paused() -> void:
	_game_view.paused = (
		_code_editor.is_pause_button_pressed() || _code_editor.is_solution_button_pressed()
	)


func _on_code_editor_text_changed(_text: String) -> void:
	_code_editor_is_dirty = true


func _on_code_editor_action_taken(which: String) -> void:
	match which:
		_code_editor.ACTIONS.RUN:
			_validate_and_run_student_code()
		_code_editor.ACTIONS.PAUSE:
			_update_game_paused()
		_code_editor.ACTIONS.DFMODE:
			_toggle_distraction_free_mode()
		_code_editor.ACTIONS.RESTORE:
			_reset_practice()
		_code_editor.ACTIONS.SOLUTION:
			_update_game_paused()
			_toggle_solution_panel()
		_code_editor.ACTIONS.CONTINUE:
			_on_next_requested()


func _on_console_toggled() -> void:
	_output_console.visible = not _output_console.visible


func _on_code_reference_clicked(_file_name: String, line: int, character: int) -> void:
	_code_editor.slice_editor.line_highlight_requested(line, character)


func _on_previous_requested() -> void:
	if not _practice:
		return

	Events.practice_previous_requested.emit(_practice)


func _on_next_requested() -> void:
	if not _practice:
		return

	Events.practice_next_requested.emit(_practice)


func _on_list_requested() -> void:
	_practice_list.show()


func _on_autotimer_timeout() -> void:
	if _run_tests_requested:
		Events.practice_run_completed.emit()


func _on_current_screen_unload_requested() -> void:
	if not _code_editor_is_dirty:
		_accept_unload()
		return

	_practice_leave_unfinished_popup.popup()


# Updates all nodes with the given script. If a node path isn't valid, the node
# will be silently skipped.
func _update_nodes(script: GDScript, node_paths: Array) -> void:
	for path in node_paths:
		var node_path: NodePath
		if path is NodePath:
			node_path = path
		elif path is String:
			node_path = NodePath(path as String)

		var node = (
			_current_scene.get_node_or_null(node_path)
			if not node_path.is_empty()
			else _current_scene
		)
		if node:
			try_validate_and_replace_script(node as Node, script)


# If a script is valid, sets it in the node and optionally calls _run()
# @param node         Node                  any valid node
# @param script       GDScript              A GDScript instance
func try_validate_and_replace_script(node: Node, script: GDScript) -> void:
	if not script.can_instantiate():
		var error_code := script.reload()
		if not script.can_instantiate():
			print("Script errored out (code %s); skipping replacement" % [error_code])
			return

	# save any @exported variables
	var properties := _get_properties(node)

	var parent = node.get_parent()
	parent.remove_child(node)
	node.request_ready()

	node.set_script(script)
	# restore @exported variables
	_restore_properties(node, properties)

	parent.call_deferred("add_child", node)

	_run_if_valid.call_deferred(node)


func _run_if_valid(target_node: Node) -> void:
	if target_node.has_method("_run"):
		if _tester.prevalidate(target_node):
			@warning_ignore("unsafe_method_access")
			target_node._run()
		else:
			_run_tests_requested = false
			Events.practice_completed.emit(_practice)
			_cleanup_post_test()


static func _get_properties(node: Node) -> Array[Dictionary]:
	var properties := node.get_property_list().filter(
		func(prop: Dictionary) -> bool:
			return (
				prop.usage & (PropertyUsageFlags.PROPERTY_USAGE_STORAGE) != 0
				and prop.usage & (PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE) != 0
			),
	)
	for property in properties:
		property.value = node.get(property.name as StringName)
	return properties


static func _restore_properties(node: Node, properties: Array[Dictionary]) -> void:
	for property in properties:
		node.set(property.name as StringName, property.value)


###############################################################################
#
# JS INTERFACE
# the below intends to listen to the `RECURSIVE` error event dispatched back
# from JS and react to it
#

# JS error event listener
var _on_js_error_feedback_ref = JavaScriptBridge.create_callback(_on_js_error_feedback)


# This will be called from Javascript
func _on_js_error_feedback(args):
	var code = args[0]
	if code is String and code == "RECURSIVE":
		print("recursive code")


# Set the event listener
func _on_init_set_javascript() -> void:
	if OS.has_feature("web"):
		var GDQUEST = JavaScriptBridge.get_interface("GDQUEST")
		@warning_ignore("unsafe_method_access")
		GDQUEST.events.onError.connect(_on_js_error_feedback_ref)


func _has_class_name(source: String) -> bool:
	return REGEX_CLASS_NAME.search(source) != null


func _find_first_non_annotation_entry_point(source: String) -> int:
	var lines := source.split("\n")
	var character_count := 0
	for i in lines.size():
		if REGEX_TOP_ANNOTATION.search(lines[i]) == null:
			break
		character_count += lines[i].length() + 1
	return character_count


# Checks if the script text has mixed tabs and spaces in indentation.
# Returns the line number of the error or -1 if there's no error
func _check_for_mixed_indentation(text: String) -> int:
	var lines := text.split("\n")
	for line_number in range(lines.size()):
		var line := lines[line_number]
		if line.is_empty() or line.strip_edges() == "":
			continue

		var has_space := false
		var has_tab := false

		for i in range(line.length()):
			var character := line[i]
			if character == ' ':
				has_space = true
			elif character == '\t':
				has_tab = true
			else:
				break

		if has_space and has_tab:
			return line_number
	return -1
