# Integration test that runs through all lessons and practices in the course.
# Tests that lessons load correctly, practices load correctly, solution code
# does solve every practice.
#
# This test does not currently run through the application navigation through
# the user interface. It currently loads the lessons and practices independently
# and just checks that individually the screens and all the content load and
# display without error and that we're able to apply the solution to a practice,
# run it, and complete the practice.
#
# A future improvement would be making it run entirely through the application
# UI, but this already safeguards things.
#
# To run, run the scene file that uses this script from the editor.
extends Node

const COURSE_PATH := "res://course/course-learn-gdscript.tres"
const UILessonScene := preload("res://ui/UILesson.tscn")
const UIPracticeScene := preload("res://ui/UIPractice.tscn")

export var time_scale := 4.0
export var lesson_load_timeout := 2.0
export var practice_setup_timeout := 2.0
export var practice_execution_timeout := 10.0

var _course_resource: Course = null

var _fail_messages := []
var _timeout_messages := []

var _tests_run_count := 0
var _tests_passed_count := 0


func _ready() -> void:
	Engine.time_scale = time_scale
	print("RUNNING INTEGRATION TEST")
	print("Time scale: %sx" % time_scale)
	print("Course path: %s\n" % COURSE_PATH)
	
	_course_resource = load(COURSE_PATH)
	if _course_resource == null:
		push_error("Failed to load _course_resource from: %s" % COURSE_PATH)
		get_tree().quit(1)
		return
	
	_run_integration_test()


func _run_integration_test() -> void:
	var total_lessons := _course_resource.lessons.size()
	var total_practices := 0
	for lesson in _course_resource.lessons:
		total_practices += lesson.practices.size()
	
	print("Course: %s" % _course_resource.title)
	print("Total lessons: %d" % total_lessons)
	print("Total practices: %d\n" % total_practices)
	
	for lesson_index in range(_course_resource.lessons.size()):
		var lesson: Lesson = _course_resource.lessons[lesson_index]
		print("[Lesson %d/%d] Testing: %s" % [lesson_index + 1, total_lessons, lesson.title])
		
		# Functions yield which in Godot 3 returns function state objects
		var awaited_lesson_test: GDScriptFunctionState = _test_lesson(lesson)
		var is_lesson_test_passed: bool = yield(awaited_lesson_test, "completed")
		if not is_lesson_test_passed:
			_fail_messages.append("Lesson %d: %s - Failed to load/display" % [lesson_index + 1, lesson.title])
			print("  FAIL - Lesson failed\n")
			continue
		
		print("  OK - Lesson loaded successfully")
		
		var practice_index := 0
		for practice in lesson.practices:
			practice_index += 1
			_tests_run_count += 1
			print("  [Practice %d/%d] Testing: %s" % [practice_index, lesson.practices.size(), practice.title])
			
			var awaited_practice_test: GDScriptFunctionState = _test_practice(practice, lesson)
			var is_practice_test_passed: bool = yield(awaited_practice_test, "completed")
			if not is_practice_test_passed:
				_fail_messages.append("Practice: %s (Lesson %d)" % [practice.title, lesson_index + 1])
				print("    FAIL - Practice failed")
			else:
				_tests_passed_count += 1
				print("    OK - Practice completed successfully")
		
		print("")
	
	_print_summary()


func _test_lesson(lesson: Lesson) -> bool:
	var ui_lesson: UILesson = UILessonScene.instance()
	add_child(ui_lesson)
	
	ui_lesson.enable_integration_test_mode()
	
	var setup_result: GDScriptFunctionState = ui_lesson.setup(lesson, _course_resource)
	yield(setup_result, "completed")
	
	var displayed := false
	var timed_out := false
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = lesson_load_timeout
	add_child(timer)
	
	var state := {"displayed": false, "timer": timer}
	ui_lesson.connect("lesson_displayed", self, "_on_lesson_displayed_signal", [state])
	timer.connect("timeout", self, "_on_lesson_timeout_signal", [state])
	timer.start()
	
	var wait_start_time := OS.get_ticks_msec()
	while not displayed and not timed_out:
		if OS.get_ticks_msec() - wait_start_time > lesson_load_timeout * 1000.0:
			timed_out = true
			break
		if state.displayed or ui_lesson._practices_visibility_container.visible:
			displayed = true
			break
		yield(get_tree(), "idle_frame")
	
	timer.queue_free()
	
	if timed_out:
		_timeout_messages.append("Lesson timeout (%.1fs): %s" % [lesson_load_timeout, lesson.title])
		ui_lesson.queue_free()
		return false
	
	if not ui_lesson._lesson or ui_lesson._lesson != lesson:
		ui_lesson.queue_free()
		return false
	
	if not ui_lesson._practices_visibility_container.visible:
		ui_lesson.queue_free()
		return false
	
	ui_lesson.queue_free()
	return true


func _on_lesson_displayed_signal(state: Dictionary) -> void:
	state.displayed = true
	if state.timer:
		state.timer.stop()


func _on_lesson_timeout_signal(state: Dictionary) -> void:
	pass


func _test_practice(practice: Practice, lesson: Lesson) -> bool:
	var ui_practice: UIPractice = UIPracticeScene.instance()
	add_child(ui_practice)
	
	ui_practice.turn_on_test_mode()
	
	var setup_result = ui_practice.setup(practice, lesson, _course_resource)
	if setup_result != null and setup_result is GDScriptFunctionState:
		yield(setup_result, "completed")
	
	var frames_waited := 0
	while frames_waited < 5:
		yield(get_tree(), "idle_frame")
		frames_waited += 1
	
	if not ui_practice._practice or ui_practice._practice != practice:
		ui_practice.queue_free()
		return false
	
	ui_practice._on_use_solution_pressed()
	
	yield(get_tree(), "idle_frame")
	
	ui_practice._validate_and_run_student_code()
	
	var execution_complete := false
	var timed_out := false
	
	var execution_timer := Timer.new()
	execution_timer.one_shot = true
	execution_timer.wait_time = practice_execution_timeout
	add_child(execution_timer)
	
	var state := {"complete": false, "timer": execution_timer}
	ui_practice.connect("test_student_code_completed", self, "_on_practice_execution_complete_signal", [state])
	execution_timer.connect("timeout", self, "_on_practice_execution_timeout_signal", [state])
	execution_timer.start()
	
	var wait_start_time := OS.get_ticks_msec()
	while not execution_complete and not timed_out:
		if OS.get_ticks_msec() - wait_start_time > practice_execution_timeout * 1000.0:
			timed_out = true
			break
		if state.complete or execution_timer.is_stopped():
			execution_complete = true
			break
		yield(get_tree(), "idle_frame")
	
	execution_timer.queue_free()
	
	if timed_out:
		_timeout_messages.append("Practice execution timeout (%.1fs): %s" % [practice_execution_timeout, practice.title])
		ui_practice.queue_free()
		return false
	
	if not ui_practice._practice_completed:
		ui_practice.queue_free()
		return false
	
	ui_practice.queue_free()
	return true


func _on_practice_execution_complete_signal(state: Dictionary) -> void:
	state.complete = true
	if state.timer:
		state.timer.stop()


func _on_practice_execution_timeout_signal(state: Dictionary) -> void:
	pass


func _print_summary() -> void:
	var separator := ""
	for i in range(50):
		separator += "="
	print("\n" + separator)
	print("Test Summary")
	print(separator)
	
	var total_lessons := _course_resource.lessons.size()
	var total_practices := 0
	for lesson in _course_resource.lessons:
		total_practices += lesson.practices.size()
	
	print("Total lessons tested: %d" % total_lessons)
	print("Total practices tested: %d" % total_practices)
	print("Tests passed: %d / %d" % [_tests_passed_count, _tests_run_count])
	print("Failures: %d" % _fail_messages.size())
	print("Timeouts: %d" % _timeout_messages.size())
	
	if _fail_messages.size() > 0:
		print("\nFailures")
		for failure in _fail_messages:
			print("  FAIL - %s" % failure)
	
	if _timeout_messages.size() > 0:
		print("\nTimeouts (Potential Bugs)")
		for timeout in _timeout_messages:
			print("  ⏱ %s" % timeout)
	
	if _fail_messages.size() == 0 and _timeout_messages.size() == 0:
		print("\nOK - All tests passed!")
		get_tree().quit(0)
	else:
		print("\nFAIL - Tests failed")
		get_tree().quit(1)

