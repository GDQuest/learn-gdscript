class_name Profile
extends Resource

signal progress_changed(exercise_name, progress)
signal scroll_sensitivity_changed(new_value)
signal framerate_limit_changed(new_value)

const VALID_FRAMERATE_LIMITS := [0, 30, 60]
const URL_GODOT_DOCS_REF = "ref=godot-docs"

# General profile details
@export var player_name := ""
# Study progression (across multiple courses)
@export var study_progression := []
@export var last_started_lesson := {}
@export var last_visible_lesson_block := {}
@export var is_sponsored_profile := true

# User settings
@export var language := "en"
# Relative size adjustment of all fonts, in integer numbers.
@export var font_size_scale := 0
# Lower contrast enabled
@export var lower_contrast := false
# Dyslexia Font enabled
@export var dyslexia_font := false
# Sensitivity when scrolling with the mouse wheel or touchpad.
@export var scroll_sensitivity := 1.0: set = set_scroll_sensitivity
# Target framerate for the application, to reduce update intensity on lower end devices.
@export var framerate_limit := 60: set = set_framerate_limit


func _init() -> void:
	study_progression = []
	last_started_lesson = {}

	if OS.has_feature("JavaScript"):
		var window := JavaScriptBridge.get_interface("window")
		var browser_url : String = window.location.href
		is_sponsored_profile = browser_url.find(URL_GODOT_DOCS_REF) == -1


func save() -> void:
	if resource_path.is_empty():
		push_error("Cannot save a file without a filename, set resource_path first.")
		return
	ResourceSaver.save(self, resource_path)
	take_over_path(resource_path)


func get_or_create_course(course_id: String) -> CourseProgress:
	for course_progress in study_progression:
		if course_progress.course_id == course_id:
			return course_progress

	var course_progress := CourseProgress.new()
	course_progress.course_id = course_id
	study_progression.append(course_progress)
	# Save when it's a new item.
	save()

	return course_progress


func get_or_create_lesson(course_id: String, lesson_id: String) -> LessonProgress:
	var course_progress := get_or_create_course(course_id)
	for lesson_progress in course_progress.lessons:
		if lesson_progress.lesson_id == lesson_id:
			return lesson_progress

	var lesson_progress := LessonProgress.new()
	lesson_progress.lesson_id = lesson_id
	course_progress.lessons.append(lesson_progress)
	# Save when it's a new item.
	save()

	return lesson_progress


func set_lesson_reading_block(course_id: String, lesson_id: String, block_id: String) -> void:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)

	# Mark the block as read, if it wasn't marked before.
	if not lesson_progress.completed_blocks.has(block_id):
		lesson_progress.completed_blocks.append(block_id)

	# Set it as the last visible block to use it later to restore position on the page.
	if not last_visible_lesson_block.has(course_id):
		last_visible_lesson_block[course_id] = {}
	last_visible_lesson_block[course_id][lesson_id] = block_id

	save()


func has_lesson_blocks_read(course_id: String, lesson_id: String) -> bool:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_progress.completed_blocks.size() > 0


func is_lesson_block_read(course_id: String, lesson_id: String, block_id: String) -> bool:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_progress.completed_blocks.has(block_id)


func get_last_visited_lesson_block(course_id: String, lesson_id: String) -> String:
	# Ensure we have some data for the course and the lesson, if we didn't have it before.
	var _course_progress := get_or_create_course(course_id)
	var _lesson_progress := get_or_create_lesson(course_id, lesson_id)

	if not last_visible_lesson_block.has(course_id):
		return ""
	if not last_visible_lesson_block[course_id].has(lesson_id):
		return ""

	return last_visible_lesson_block[course_id][lesson_id]


func set_lesson_reading_completed(course_id: String, lesson_id: String, completed: bool) -> void:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	lesson_progress.completed_reading = completed
	save()


func is_lesson_reading_completed(course_id: String, lesson_id: String) -> bool:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_progress.completed_reading


func set_lesson_quiz_completed(
	course_id: String, lesson_id: String, quiz_id: String, completed: bool
) -> void:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)

	var quiz_listed := lesson_progress.completed_quizzes.has(quiz_id)
	if completed and not quiz_listed:
		lesson_progress.completed_quizzes.append(quiz_id)
	elif not completed and quiz_listed:
		lesson_progress.completed_quizzes.erase(quiz_id)

	save()


func is_lesson_quiz_completed(course_id: String, lesson_id: String, quiz_id: String) -> bool:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_progress.completed_quizzes.has(quiz_id)


func set_lesson_practice_completed(
	course_id: String, lesson_id: String, practice_id: String, completed: bool
) -> void:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)

	var practice_listed := lesson_progress.completed_practices.has(practice_id)
	if completed and not practice_listed:
		lesson_progress.completed_practices.append(practice_id)
	elif not completed and practice_listed:
		lesson_progress.completed_practices.erase(practice_id)

	save()


func is_lesson_practice_completed(course_id: String, lesson_id: String, practice_id: String) -> bool:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_progress.completed_practices.has(practice_id)


func set_last_started_lesson(course_id: String, lesson_id: String) -> void:
	# Ensure we have some data for the course and the lesson, if we didn't have it before.
	var _course_progress := get_or_create_course(course_id)
	var _lesson_progress := get_or_create_lesson(course_id, lesson_id)
	# Store the last started lesson.
	last_started_lesson[course_id] = lesson_id

	save()


func get_last_started_lesson(course_id: String) -> String:
	# Ensure we have some data for the course, if we didn't have it before.
	var _course_progress := get_or_create_course(course_id)
	var lesson_id := ""
	if last_started_lesson.has(course_id):
		lesson_id = last_started_lesson[course_id]

	if lesson_id.is_empty():
		return ""

	# Ensure we have some data for the lesson, if we didn't have it before.
	var _lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_id


func reset_course_progress(course_id: String) -> void:
	var course_progress := get_or_create_course(course_id)
	course_progress.reset()

	if last_visible_lesson_block.has(course_id):
		last_visible_lesson_block.erase(course_id)

	if last_started_lesson.has(course_id):
		last_started_lesson.erase(course_id)

	save()


func set_scroll_sensitivity(amount: float) -> void:
	scroll_sensitivity = max(amount, 0.1)
	emit_signal("scroll_sensitivity_changed", scroll_sensitivity)


func set_framerate_limit(limit: int) -> void:
	assert(
		limit in VALID_FRAMERATE_LIMITS,
		"The framerate limit must be one of: " + str(VALID_FRAMERATE_LIMITS)
	)
	framerate_limit = limit
	emit_signal("framerate_limit_changed", framerate_limit)
