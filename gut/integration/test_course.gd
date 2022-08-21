extends GutTest


const course_learn_gdscript := preload("res://course/course-learn-gdscript.tres")

const UIPracticeScene := preload("res://ui/UIPractice.tscn")



func test_course() -> void:
	for lesson in course_learn_gdscript.lessons:
		for practice in lesson.practices:
			var ui_practice = UIPracticeScene.instance()
			add_child(ui_practice)
			ui_practice.turn_on_test_mode()
			ui_practice.setup(practice, null, null)
			ui_practice._on_use_solution_pressed()
			ui_practice._run_tests_requested = true
			ui_practice._run_autotimer.start()
			ui_practice._test_student_code()
			yield(ui_practice, "test_student_code_completed")
			assert_true(ui_practice._practice_completed)
			autoqfree(ui_practice)

