tool
class_name UIPractice
extends UINavigatablePage

const RUN_AUTOTIMER_DURATION := 5.0
const SLIDE_TRANSITION_DURATION := 0.5

const PracticeHintScene := preload("screens/practice/PracticeHint.tscn")
const PracticeListPopup := preload("components/popups/PracticeListPopup.gd")
const PracticeDonePopup := preload("components/popups/PracticeDonePopup.gd")
const PracticeLeaveUnfinishedPopup := preload("components/popups/PracticeLeaveUnfinishedPopup.gd")

export var test_practice: Resource

var _practice: Practice
var _practice_completed := false
var _practice_solution_used := false

var _script_slice: SliceProperties setget _set_script_slice
var _tester: PracticeTester
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
var _current_scene_reset_values := {
	visible = null,
	transform = null,
}

onready var _layout_container := $Margin/Layout as Control

onready var _output_container := find_node("Output") as Control
onready var _game_container := find_node("GameContainer") as Container
onready var _game_view := _output_container.find_node("GameView") as GameView
onready var _output_console := _output_container.find_node("Console") as OutputConsole

onready var _output_anchors := $Margin/Layout/OutputAnchors as Control
onready var _solution_panel := find_node("SolutionContainer") as Control
onready var _solution_editor := _solution_panel.find_node("SliceEditor") as SliceEditor
onready var _use_solution_button := _solution_panel.find_node("UseSolutionButton") as Button

onready var _info_panel_anchors := $Margin/Layout/InfoPanelAnchors as Control
onready var _info_panel := find_node("PracticeInfoPanel") as PracticeInfoPanel
onready var _documentation_panel := find_node("DocumentationPanel") as RichTextLabel
onready var _hints_container := _info_panel.hints_container as Revealer

onready var _practice_list := find_node("PracticeListPopup") as PracticeListPopup
onready var _practice_done_popup := find_node("PracticeDonePopup") as PracticeDonePopup
onready var _practice_leave_unfinished_popup := find_node("PracticeLeaveUnfinishedPopup") as PracticeLeaveUnfinishedPopup

onready var _code_editor := find_node("CodeEditor") as CodeEditor

onready var _tween := $Tween as Tween

func _init():
	_run_autotimer = Timer.new()
	_run_autotimer.one_shot = true
	_run_autotimer.wait_time = RUN_AUTOTIMER_DURATION
	add_child(_run_autotimer)

	_run_autotimer.connect("timeout", self, "_on_autotimer_timeout")

	_on_init_set_javascript()


func _ready() -> void:
	randomize()
	if Engine.editor_hint:
		return

	_code_editor.connect("action_taken", self, "_on_code_editor_action_taken")
	_code_editor.connect("text_changed", self, "_on_code_editor_text_changed")
	_code_editor.connect("console_toggled", self, "_on_console_toggled")
	_output_console.connect("reference_clicked", self, "_on_code_reference_clicked")
	_use_solution_button.connect("pressed", self, "_on_use_solution_pressed")

	_info_panel.connect("list_requested", self, "_on_list_requested")

	_practice_done_popup.connect("accepted", self, "_on_next_requested")

	_practice_leave_unfinished_popup.connect("confirmed", self, "_accept_unload")
	_practice_leave_unfinished_popup.connect("denied", self, "_deny_unload")

	Events.connect("practice_run_completed", self, "_test_student_code")

	_update_slidable_panels()
	_layout_container.connect("resized", self, "_update_slidable_panels")

	_solution_panel.modulate.a = 0.0
	_solution_panel.margin_left = _output_anchors.rect_size.x

	if test_practice and get_parent() == get_tree().root:
		setup(test_practice, null, null)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_slidable_panels()
		_update_labels()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == BUTTON_LEFT and mb.pressed and get_focus_owner():
		# Makes clicks on the empty area to remove focus from various controls, specifically
		# the code editor.
		get_focus_owner().release_focus()


func setup(practice: Practice, lesson: Lesson, course: Course) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_practice = practice
	_practice_completed = false
	_practice_solution_used = false

	_info_panel.title_label.text = tr(practice.title).capitalize()
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_info_panel.goal_rich_text_label.bbcode_text = TextUtils.bbcode_add_code_color(tr(practice.goal.replace("\r\n", "\n")))
	_code_editor.text = practice.starting_code
	_code_editor.update_cursor_position(practice.cursor_line, practice.cursor_column)

	_hints_container.visible = not practice.hints.empty()
	var index := 0
	for hint in practice.hints:
		var practice_hint: PracticeHint = PracticeHintScene.instance()
		practice_hint.title = tr("Hint %s") % [ String(index + 1).pad_zeros(1) ]
		practice_hint.bbcode_text = tr(hint)
		_hints_container.add_child(practice_hint)
		index += 1

	# TODO: Should probably avoid relying on content ID for getting paths.
	var base_directory := practice.practice_id.get_base_dir()

	var slice_path := practice.script_slice_path
	if slice_path.is_rel_path():
		slice_path = base_directory.plus_file(slice_path)
	_set_script_slice(load(slice_path))
	_code_editor.slice_editor.setup(_script_slice)
	_code_editor.set_continue_allowed(false)

	_solution_editor.text = _script_slice.slice_text

	var validator_path := practice.validator_script_path
	if validator_path.is_rel_path():
		validator_path = base_directory.plus_file(validator_path)
	_tester = (load(validator_path) as GDScript).new()
	_tester.setup(_game_view.get_viewport(), _script_slice)

	var documentation_reference := _practice.get_documentation_raw()
	if documentation_reference.is_empty():
		_info_panel.clear_documentation()
	else:
		_info_panel.set_documentation(documentation_reference)

	_info_panel.display_tests(_tester.get_test_names())
	_game_view.use_scene(_current_scene, _script_slice.get_scene_properties().viewport_size)

	# In case we directly test a practice from the editor, we don't have access to the lesson.
	if lesson and course:
		_practice_list.clear_items()
		for practice_data in lesson.practices:
			_practice_list.add_item(practice_data, lesson, course, practice_data == practice)

		var user_profile := UserProfiles.get_profile()
		var completed_before = user_profile.is_lesson_practice_completed(course.resource_path, lesson.resource_path, practice.practice_id)
		if completed_before:
			_info_panel.set_status_icon(_info_panel.Status.COMPLETED_BEFORE)


func _update_labels() -> void:
	if not _practice:
		return
	
	_info_panel.title_label.text = tr(_practice.title).capitalize()
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_info_panel.goal_rich_text_label.bbcode_text = TextUtils.bbcode_add_code_color(tr(_practice.goal.replace("\r\n", "\n")))
	
	var index := 0
	for child_node in _hints_container.get_children():
		var practice_hint = child_node as PracticeHint
		if not practice_hint:
			continue
		
		practice_hint.title = tr("Hint %s") % [ String(index + 1).pad_zeros(1) ]
		practice_hint.bbcode_text = tr(_practice.hints[index])
		index += 1
	
	_info_panel.display_tests(_tester.get_test_names())


func get_screen_resource() -> Practice:
	return _practice


func _set_script_slice(new_slice: SliceProperties) -> void:
	if new_slice == _script_slice:
		return
	_script_slice = new_slice
	_output_console.setup(_script_slice)

	_current_scene = _script_slice.get_scene_properties().scene.instance()
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
	var script_text := _script_slice.current_full_text
	var script_file_name := _script_slice.get_script_properties().file_name
	var script_file_path := _script_slice.get_script_properties().file_path.lstrip("res://")

	# Do local sanity checks for the script.
	var recursive_function := MiniGDScriptTokenizer.new(script_text).find_any_recursive_function()
	if recursive_function != "":
		var error = make_error_recursive_function(recursive_function)
		MessageBus.print_script_error(error, script_file_name)
		_code_editor.unlock_editor()
		return

	var errors := _run_check(script_text)

	if not errors.empty():
		_code_editor.slice_editor.errors = errors

		for index in errors.size():
			var error: ScriptError = errors[index]
			MessageBus.print_script_error(error, script_file_name)

		var is_missing_parser_error: bool = (
			errors.size() == 1 and \
			OfflineScriptVerifier.check_error_is_missing_parser_error(errors[0])
		)
		
		if not is_missing_parser_error:
			_code_editor.unlock_editor()
			return

	_run_student_code()


func _run_check(script_text: String) -> Array:
	var verifier := OfflineScriptVerifier.new(script_text)
	verifier.test()
	return verifier.errors


func _run_student_code() -> void:
	var script_text := _script_slice.current_full_text
	var script_file_name := _script_slice.get_script_properties().file_name
	var nodes_paths := _script_slice.get_script_properties().nodes_paths

	# Generate a runnable script, check for uncaught errors.
	_code_editor.set_locked_message(tr("Running Your Code..."))
	yield(get_tree(), "idle_frame")

	script_text = MessageBus.replace_script(script_file_name, script_text)
	var script = GDScript.new()
	script.source_code = script_text

	var script_is_valid = script.reload()
	if script_is_valid != OK:
		var error := make_error_script_silent()
		MessageBus.print_script_error(error, script_file_name)
		_code_editor.unlock_editor()
		return

	_code_editor_is_dirty = false

	# Start the auto-timer used to perform tests in case the scene doesn't emit the required signal.
	_run_tests_requested = true
	_run_autotimer.start()
	# Reset and run the test scene.
	_update_nodes(script, nodes_paths)


func _test_student_code() -> void:
	if not _run_tests_requested:
		return
	_run_tests_requested = false

	var script_file_name := _script_slice.get_script_properties().file_name

	# Run tests on the scene.
	_code_editor.set_locked_message(tr("Running Tests..."))
	_info_panel.set_tests_pending()

	var result := _tester.run_tests()
	_info_panel.set_tests_status(result, script_file_name)
	yield(_info_panel, "tests_updated")

	# Show the end of practice popup.
	if not _practice_completed and result.is_success():
		_practice_completed = true

		if not _practice_solution_used:
			Events.emit_signal("practice_completed", _practice)

		_practice_done_popup.show()
		_practice_done_popup.fade_in(_game_container)

	# Clean-up.
	_code_editor.unlock_editor()
	if _practice_completed:
		_code_editor.set_continue_allowed(true)


func _reset_practice() -> void:
	# Code is already reset by the slice editor.

	_info_panel.reset_tests_status()
	_code_editor.slice_editor.errors = []
	_output_console.clear_messages()

	if _current_scene.has_method("reset"):
		_current_scene.call("reset")
		for property in _current_scene_reset_values:
			_current_scene.set(property, _current_scene_reset_values[property])


func _update_slidable_panels() -> void:
	# Wait a frame to make sure the new size has been applied.
	yield(get_tree(), "idle_frame")

	# We use _output_anchors for reference because it never leaves the screen, so we can rely on it
	# to always report the target size for one third of the hbox.

	# Update info panel.
	_info_panel.rect_min_size = Vector2(_output_anchors.rect_size.x, 0)
	_info_panel.set_anchors_and_margins_preset(Control.PRESET_WIDE, Control.PRESET_MODE_MINSIZE)

	# Update solution panel.
	_solution_panel.rect_min_size = Vector2(_output_anchors.rect_size.x, 0)
	_solution_panel.set_anchors_and_margins_preset(Control.PRESET_WIDE, Control.PRESET_MODE_MINSIZE)
	if not _is_solution_panel_open:
		_solution_panel.margin_left = _output_anchors.rect_size.x


func _toggle_distraction_free_mode() -> void:
	if _is_info_panel_open:
		_enable_distraction_free_mode()
	else:
		_disable_distraction_free_mode()


func _disable_distraction_free_mode() -> void:
	_update_slidable_panels()

	_is_info_panel_open = true
	_tween.stop_all()

	_tween.interpolate_property(
		_info_panel_anchors,
		"size_flags_stretch_ratio",
		_info_panel_anchors.size_flags_stretch_ratio,
		1.0,
		SLIDE_TRANSITION_DURATION,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	_tween.interpolate_property(
		_code_editor,
		"size_flags_stretch_ratio",
		_code_editor.size_flags_stretch_ratio,
		1.0,
		SLIDE_TRANSITION_DURATION,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	_tween.interpolate_property(
		_info_panel_anchors,
		"modulate:a",
		_info_panel_anchors.modulate.a,
		1.0,
		SLIDE_TRANSITION_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)

	_tween.start()
	_code_editor.set_distraction_free_state(not _is_info_panel_open)


func _enable_distraction_free_mode() -> void:
	_update_slidable_panels()

	_is_info_panel_open = false
	_tween.stop_all()

	_tween.interpolate_property(
		_info_panel_anchors,
		"size_flags_stretch_ratio",
		_info_panel_anchors.size_flags_stretch_ratio,
		0.0,
		SLIDE_TRANSITION_DURATION,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	_tween.interpolate_property(
		_code_editor,
		"size_flags_stretch_ratio",
		_code_editor.size_flags_stretch_ratio,
		2.0,
		SLIDE_TRANSITION_DURATION,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	_tween.interpolate_property(
		_info_panel_anchors,
		"modulate:a",
		_info_panel_anchors.modulate.a,
		0.0,
		SLIDE_TRANSITION_DURATION - 0.25,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN,
		0.15
	)

	_tween.start()
	_code_editor.set_distraction_free_state(not _is_info_panel_open)


func _toggle_solution_panel() -> void:
	if _is_solution_panel_open:
		_hide_solution_panel()
	else:
		_show_solution_panel()


func _show_solution_panel() -> void:
	_update_slidable_panels()

	_is_solution_panel_open = true
	_tween.stop_all()

	_tween.interpolate_property(
		_solution_panel,
		"margin_left",
		_solution_panel.margin_left,
		0.0,
		SLIDE_TRANSITION_DURATION,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	_tween.interpolate_property(
		_solution_panel,
		"modulate:a",
		_solution_panel.modulate.a,
		1.0,
		SLIDE_TRANSITION_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)

	_tween.start()


func _hide_solution_panel() -> void:
	_update_slidable_panels()

	_is_solution_panel_open = false
	_tween.stop_all()

	_tween.interpolate_property(
		_solution_panel,
		"margin_left",
		_solution_panel.margin_left,
		_output_anchors.rect_size.x,
		SLIDE_TRANSITION_DURATION,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	_tween.interpolate_property(
		_solution_panel,
		"modulate:a",
		_solution_panel.modulate.a,
		0.0,
		SLIDE_TRANSITION_DURATION - 0.25,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN,
		0.15
	)

	_tween.start()


func _on_use_solution_pressed() -> void:
	_code_editor.slice_editor.sync_text_with_slice()

	_practice_solution_used = true
	_info_panel.set_status_icon(_info_panel.Status.SOLUTION_USED)

	_hide_solution_panel()
	_code_editor.set_solution_button_pressed(false)
	_code_editor.set_restore_allowed(true)
	_update_game_paused()


func _update_game_paused() -> void:
	_game_view.paused = _code_editor.is_pause_button_pressed() || _code_editor.is_solution_button_pressed()


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
	_code_editor.slice_editor.highlight_line(line, character)


func _on_previous_requested() -> void:
	if not _practice:
		return

	Events.emit_signal("practice_previous_requested", _practice)


func _on_next_requested() -> void:
	if not _practice:
		return

	Events.emit_signal("practice_next_requested", _practice)


func _on_list_requested() -> void:
	_practice_list.show()


func _on_autotimer_timeout() -> void:
	if _run_tests_requested:
		Events.emit_signal("practice_run_completed")


func _on_current_screen_unload_requested() -> void:
	if not _code_editor_is_dirty:
		_accept_unload()
		return

	_practice_leave_unfinished_popup.popup()


# Updates all nodes with the given script. If a node path isn't valid, the node
# will be silently skipped.
func _update_nodes(script: GDScript, node_paths: Array) -> void:
	for node_path in node_paths:
		if node_path is NodePath or node_path is String:
			var node = (
				_current_scene.get_node_or_null(node_path)
				if node_path != ""
				else _current_scene
			)
			if node:
				try_validate_and_replace_script(node, script)


# If a script is valid, sets in the node. Optionally restores variables and
# optionally calls _run()
# @param node         Node                  any valid node
# @param script       GDScript              A GDScript instance
# @param props_backup Dictionary[string, *] An optional dictionary of properties
#                                           to restore before calling `_run()`
static func try_validate_and_replace_script(node: Node, script: GDScript, props_backup := {}) -> void:
	if not script.can_instance():
		var error_code := script.reload()
		if not script.can_instance():
			print("Script errored out (code %s); skipping replacement" % [error_code])
			return

	var parent = node.get_parent()
	parent.remove_child(node)
	node.request_ready()

	node.set_script(script)

	parent.add_child(node)

	# props_backup = backup_node_properties(node)

	if props_backup.size() > 0:
		set_node_properties(node, props_backup)

	if node.has_method("_run"):
		# warning-ignore:unsafe_method_access
		node._run()


# Saves all the node's properties in a dictionary. Useful in case you want to
# change back properties of a node after setting a script
# You can optionally pass an array of property names you want (any property you
# do not specify will be left out)
# @param node              Node            any valid node
# @param select_properties PoolStringArray an array of property names. Leave it
#                                          out (or pass an empty array) to select
#                                          all properties
static func backup_node_properties(node: Node, select_properties := PoolStringArray()) -> Dictionary:
	var props_backup := {}
	var node_original_props := node.get_property_list()
	var select_all := select_properties.size() == 0
	var select_cache := {}
	for prop_name in select_properties:
		select_cache[prop_name] = true
	for prop in node_original_props:
		var prop_name: String = prop.name
		if prop_name == "script":
			continue
		if select_all or (prop_name in select_cache):
			props_backup[prop_name] = node.get(prop_name)
	return props_backup


# Sets a node's properties from a dictionary. Intended to be used after having
# saved them prior to changing the script
static func set_node_properties(node: Node, props_backup: Dictionary) -> void:
	for prop_name in props_backup:
		if not (prop_name in node):  # In case a property is removed
			continue
		var current_value = node.get(prop_name)
		var backed_up_value = props_backup[prop_name]
		if current_value == backed_up_value:
			continue
		node.set(prop_name, backed_up_value)


static func make_error_script_silent() -> ScriptError:
		var err = ScriptError.new()
		err.message = "Oh no! The script has an error, but the Script Verifier did not catch it"
		err.severity = 1
		err.code = GDQuestCodes.ErrorCode.INVALID_NO_CATCH
		return err


static func make_error_recursive_function(func_name: String) -> ScriptError:
	var err = ScriptError.new()
	err.message = "The function `%s` calls itself, this creates an infinite loop"%[func_name]
	err.severity = 1
	err.code = GDQuestCodes.ErrorCode.RECURSIVE_FUNCTION
	return err


###############################################################################
#
# JS INTERFACE
# the below intends to listen to the `RECURSIVE` error event dispatched back
# from JS and react to it
#

# JS error event listener
var _on_js_error_feedback_ref = JavaScript.create_callback(self, "_on_js_error_feedback")


# This will be called from Javascript
func _on_js_error_feedback(args):
	var code = args[0]
	if code is String and code == 'RECURSIVE':
		print("recursive code")


# Set the event listener
func _on_init_set_javascript() -> void:
	if OS.has_feature('JavaScript'):
		var GDQUEST = JavaScript.get_interface("GDQUEST")
		GDQUEST.events.onError.connect(_on_js_error_feedback_ref)
