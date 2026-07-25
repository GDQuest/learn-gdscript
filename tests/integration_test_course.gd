# Integration test that runs through all lessons and practices in the course.
# Tests that lessons load correctly, practices load correctly, solution code
# does solve every practice.
extends Node

const COURSE_ID := "learn-gdscript"
const TEST_PROFILE_NAME := "IntegrationTest"
const UILessonScene := preload("res://ui/UILesson.tscn")
const UIPracticeScene := preload("res://ui/UIPractice.tscn")


class IntegrationTestResult:
	var kind: String
	var target: String
	var stable_id: String
	var canonical_path_to_content: String
	var passed: bool
	var phase: String
	var message: String


	func _init(
		result_kind: String,
		result_target: String,
		result_passed: bool,
		result_phase: String,
		result_message: String,
		result_canonical_path: String,
		result_stable_id: String,
	) -> void:
		kind = result_kind
		target = result_target
		passed = result_passed
		phase = result_phase
		message = result_message
		canonical_path_to_content = result_canonical_path
		stable_id = result_stable_id


@export var time_scale := 8.0
@export var lesson_load_timeout := 2.0
@export var practice_execution_timeout := 10.0

var _course_index: CourseIndex
var _lesson_filter := 0
var _practice_filter := 0
var _test_results: Array[IntegrationTestResult] = []
var _discovered_lesson_count := 0
var _discovered_practice_count := 0
var _attempted_lesson_count := 0
var _attempted_practice_count := 0


func _ready() -> void:
	Engine.time_scale = time_scale
	UserProfiles.get_profile(TEST_PROFILE_NAME)
	TranslationManager.set_language(TranslationManager.DEFAULT_LOCALE)
	TranslationServer.set_locale(TranslationManager.DEFAULT_LOCALE)

	# Check command line arguments for filters to run a specific lesson or practice
	var arguments := OS.get_cmdline_user_args()
	for argument in arguments:
		if argument.begins_with("--lesson="):
			_lesson_filter = _parse_location_number(argument.trim_prefix("--lesson="), "L")
		elif argument.begins_with("--practice="):
			var practice_location := argument.trim_prefix("--practice=").replace(".", "")
			var lesson_number := _parse_location_number(practice_location, "L")
			var practice_regex := RegEx.new()
			practice_regex.compile("^L[0-9]+P([0-9]+)")
			var practice_match := practice_regex.search(practice_location.to_upper())
			var practice_number := int(practice_match.get_string(1)) if practice_match else 0
			if lesson_number > 0 and practice_number > 0:
				_lesson_filter = lesson_number
				_practice_filter = practice_number

	print("RUNNING INTEGRATION TEST")
	print("Time scale: %sx" % time_scale)
	print("Profile: %s" % TEST_PROFILE_NAME)
	print("Locale: %s" % TranslationManager.DEFAULT_LOCALE)
	print("Filters: lesson=%s practice=%s\n" % [_lesson_filter, _practice_filter])

	_course_index = CourseIndexPaths.get_course_index_instance(COURSE_ID)
	if _course_index == null:
		_record_result(
			"course",
			COURSE_ID,
			false,
			"setup",
			"Failed to load course index",
			"",
			COURSE_ID,
		)
		_print_summary()
		return

	_discovered_lesson_count = _course_index.get_lessons_count()
	for lesson_index in _discovered_lesson_count:
		var lesson := NavigationManager.get_navigation_resource(
			_course_index.get_lesson_path(lesson_index)
		) as BBCodeParser.ParseNode
		_discovered_practice_count += BBCodeUtils.get_lesson_practice_count(lesson)
	_run_integration_test()


func _parse_location_number(value: String, prefix: String) -> int:
	var regex := RegEx.new()
	regex.compile("^" + prefix + "([0-9]+)")
	var match := regex.search(value.to_upper())
	return int(match.get_string(1)) if match else 0


func _run_integration_test() -> void:
	var total_lessons := _course_index.get_lessons_count()
	var first_lesson := _lesson_filter if _lesson_filter > 0 else 1
	var last_lesson := _lesson_filter if _lesson_filter > 0 else total_lessons

	for lesson_number in range(first_lesson, last_lesson + 1):
		if lesson_number > total_lessons:
			_record_result(
				"lesson",
				"L%d" % lesson_number,
				false,
				"selection",
				"Lesson does not exist",
				"",
				"",
			)
			continue

		var lesson := NavigationManager.get_navigation_resource(
			_course_index.get_lesson_path_from_number(lesson_number)
		) as BBCodeParser.ParseNode
		_attempted_lesson_count += 1
		var lesson_title := BBCodeUtils.get_lesson_title(lesson)
		print("[Lesson %d/%d] Testing: %s" % [lesson_number, total_lessons, lesson_title])

		var lesson_result := await _test_lesson(lesson)
		_record_result(
			"lesson",
			"L%d" % lesson_number,
			lesson_result.passed,
			lesson_result.phase,
			lesson_result.message,
			lesson.bbcode_path,
			_course_index.get_lesson_slug_from_path(lesson.bbcode_path),
		)
		if not lesson_result.passed:
			print("  FAIL - %s\n" % lesson_result.message)
			continue
		print("  OK - Lesson loaded successfully")

		var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
		var first_practice := _practice_filter if _practice_filter > 0 else 1
		var last_practice := _practice_filter if _practice_filter > 0 else practice_count
		for practice_number in range(first_practice, last_practice + 1):
			if practice_number > practice_count:
				_record_result(
					"practice",
					"L%d.P%d" % [lesson_number, practice_number],
					false,
					"selection",
					"Practice does not exist",
					"",
					"",
				)
				continue

			var practice := BBCodeUtils.get_lesson_practice(lesson, practice_number - 1)
			_attempted_practice_count += 1
			var practice_title := BBCodeUtils.get_practice_title(practice)
			print(
				"  [Practice %d/%d] Testing: %s" % [practice_number, practice_count, practice_title]
			)
			var practice_result := await _test_practice(practice, lesson)
			var practice_id := BBCodeUtils.get_practice_id(practice)
			_record_result(
				"practice",
				"L%d.P%d" % [lesson_number, practice_number],
				practice_result.passed,
				practice_result.phase,
				practice_result.message,
				practice.bbcode_path,
				practice_id,
			)
			print(
				"    %s - %s"
				% ["OK" if practice_result.passed else "FAIL", practice_result.message]
			)

	_print_summary()


func _test_lesson(lesson: BBCodeParser.ParseNode) -> Dictionary:
	var ui_lesson: UILesson = UILessonScene.instantiate()
	add_child(ui_lesson)
	ui_lesson.enable_integration_test_mode()
	var state := { "displayed": false }
	ui_lesson.lesson_displayed.connect(
		func() -> void:
			state.displayed = true,
	)
	await ui_lesson.setup(
		lesson,
		_course_index,
		_course_index.get_lesson_number(lesson.bbcode_path),
	)
	var wait_result := await _wait_for_state(state, "displayed", lesson_load_timeout)
	var result := { "passed": false, "phase": "display", "message": wait_result }
	if wait_result == "":
		result.passed = (
			ui_lesson._lesson == lesson and ui_lesson._practices_visibility_container.visible
		)
		result.message = "lesson displayed" if result.passed else "lesson content did not become visible"
	ui_lesson.queue_free()
	return result


func _test_practice(practice: BBCodeParser.ParseNode, lesson: BBCodeParser.ParseNode) -> Dictionary:
	var ui_practice: UIPractice = UIPracticeScene.instantiate()
	add_child(ui_practice)
	ui_practice.turn_on_test_mode()
	await ui_practice.setup(
		practice,
		lesson,
		_course_index,
		_course_index.get_lesson_number(lesson.bbcode_path),
	)
	if ui_practice._practice != practice:
		ui_practice.queue_free()
		return { "passed": false, "phase": "setup", "message": "practice content did not load" }

	var state := { "completed": false }
	ui_practice.test_student_code_completed.connect(
		func() -> void:
			state.completed = true,
	)
	ui_practice._on_use_solution_pressed()
	ui_practice._validate_and_run_student_code()
	var wait_result := await _wait_for_state(state, "completed", practice_execution_timeout)
	var result := {
		"passed": wait_result == "" and ui_practice._practice_completed,
		"phase": "execution",
		"message": wait_result,
	}
	if wait_result == "":
		result.message = "practice completed" if result.passed else "reference solution failed validation"
	if not result.passed and ui_practice.last_test_result:
		var diagnostics := []
		for check_name: String in ui_practice.last_test_result.errors:
			diagnostics.append(
				"%s: %s" % [check_name, ui_practice.last_test_result.errors[check_name]]
			)
		if not diagnostics.is_empty():
			result.message += " (" + "; ".join(diagnostics) + ")"
	ui_practice.queue_free()
	return result


func _wait_for_state(state: Dictionary, key: String, timeout: float) -> String:
	var deadline := Time.get_ticks_msec() + ceili(timeout * 1000.0)
	while not state.get(key, false):
		if Time.get_ticks_msec() >= deadline:
			return "timeout after %.1fs" % timeout
		await get_tree().process_frame
	return ""


func _record_result(
	kind: String,
	target: String,
	passed: bool,
	phase: String,
	message: String,
	canonical_path_to_content: String,
	stable_id: String,
) -> void:
	_test_results.append(
		IntegrationTestResult.new(kind, target, passed, phase, message, canonical_path_to_content, stable_id)
	)


func _print_summary() -> void:
	var separator := ""
	for i in range(50):
		separator += "="
	print("\n" + separator)
	print("Test Summary")
	print(separator)

	var passed := 0
	var failures: Array[IntegrationTestResult] = []
	for result in _test_results:
		if result.passed:
			passed += 1
		else:
			failures.append(result)

	print("Tests passed: %d / %d" % [passed, _test_results.size()])
	print(
		"Lessons attempted: %d / %d discovered"
		% [_attempted_lesson_count, _discovered_lesson_count]
	)
	print(
		"Practices attempted: %d / %d discovered"
		% [_attempted_practice_count, _discovered_practice_count]
	)
	print("Failures: %d" % failures.size())
	for failure in failures:
		print(
			"  FAIL - %s %s (%s) [%s]: %s"
			% [
				failure.kind,
				failure.target,
				failure.stable_id if failure.stable_id else failure.canonical_path_to_content,
				failure.phase,
				failure.message,
			]
		)
	var error_code := 0 if failures.is_empty() else 1
	get_tree().quit(error_code)
