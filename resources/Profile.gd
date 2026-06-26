## User profile data, used for tracking and serialization. Contains user settings, as well
## as study progress data.
class_name Profile
extends Resource

signal scroll_sensitivity_changed(new_value: float)
signal framerate_limit_changed(new_value: int)

const VALID_FRAMERATE_LIMITS: Array[int] = [0, 30, 60]
const URL_GODOT_DOCS_REF := "ref=godot-docs"

# General profile details

## Name of the profile.
@export var player_name: String = ""
## Course progression data.
@export var study_progression: Array[CourseProgress] = []
## Map of last started lessons per course.
@export var last_started_lesson: Dictionary[String, String] = {}
## Flag that enables the sponsored mode for the profile.
@export var is_sponsored_profile: bool = true

# User settings

## Application language.
@export var language: String = "en"
## Relative size adjustment for all fonts, in integer steps.
@export var font_size_scale: int = 0
## Flag that enables the lower contrast mode.
@export var lower_contrast: bool = false
## Flag that enables a dyslexia-friendly font.
@export var dyslexia_font: bool = false
## Sensitivity when scrolling with the mouse wheel or touchpad.
@export_range(0.1, 4.0, 0.01, "or_greater") var scroll_sensitivity: float = 1.0:
	set = set_scroll_sensitivity
## Target framerate for the application, to reduce update intensity on lower end devices.
@export_range(0, 240, 10, "or_greater") var framerate_limit: int = 60:
	set = set_framerate_limit
## Flag that allows only partially translated lessons to still be accessed
@export var access_incomplete_translations := false

var _save_queued := false


func _init() -> void:
	if OS.has_feature("JavaScript"):
		var window := JavaScriptBridge.get_interface("window")
		@warning_ignore("unsafe_property_access")
		var browser_url: String = window.location.href
		is_sponsored_profile = browser_url.find(URL_GODOT_DOCS_REF) == -1


# I/O.

func save() -> void:
	if _save_queued:
		return

	_save_queued = true
	_run_save.call_deferred()


func _run_save() -> void:
	if resource_path.is_empty():
		push_error("Cannot save a file without a filename, set resource_path first.")
		return

	ResourceSaver.save(self, resource_path)
	take_over_path(resource_path)
	_save_queued = false


# Study management.

func get_or_create_course(course_id: String) -> CourseProgress:
	if course_id.is_empty():
		return null

	for course_progress in study_progression:
		if course_progress.course_id == course_id:
			return course_progress

	var course_progress := CourseProgress.new()
	course_progress.course_id = course_id
	study_progression.push_back(course_progress)
	save() # Save new item.

	return course_progress


func get_or_create_lesson(course_id: String, lesson_id: String) -> LessonProgress:
	if course_id.is_empty() or lesson_id.is_empty():
		return null

	var course_progress := get_or_create_course(course_id)
	for lesson_progress in course_progress.lessons:
		if lesson_progress.lesson_id == lesson_id:
			return lesson_progress

	var lesson_progress := LessonProgress.new()
	lesson_progress.lesson_id = lesson_id
	course_progress.lessons.push_back(lesson_progress)
	save() # Save new item.

	return lesson_progress


func set_lesson_reading_completed(course_id: String, lesson_id: String, completed: bool) -> void:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	lesson_progress.completed_reading = completed
	save()


func is_lesson_reading_completed(course_id: String, lesson_id: String) -> bool:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_progress.completed_reading


func set_lesson_quiz_completed(
		course_id: String,
		lesson_id: String,
		quiz_id: String,
		completed: bool,
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
		course_id: String,
		lesson_id: String,
		practice_id: String,
		completed: bool,
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
	# Ensure that the course and lesson data exists first.
	get_or_create_course(course_id)
	get_or_create_lesson(course_id, lesson_id)

	last_started_lesson[course_id] = lesson_id
	save()


func get_last_started_lesson(course_id: String) -> String:
	# Ensure that the course data exists first.
	get_or_create_course(course_id)

	if not last_started_lesson.has(course_id):
		return ""

	var lesson_id := last_started_lesson[course_id]
	if lesson_id.is_empty():
		return ""

	# Ensure that the lesson data exists too.
	get_or_create_lesson(course_id, lesson_id)
	return lesson_id


func reset_course_progress(course_id: String) -> void:
	var course_progress := get_or_create_course(course_id)
	course_progress.reset()
	last_started_lesson.erase(course_id)

	save()


func set_scroll_sensitivity(amount: float) -> void:
	scroll_sensitivity = maxf(amount, 0.1)
	scroll_sensitivity_changed.emit(scroll_sensitivity)


func set_access_incomplete_translations(allow_access: bool) -> void:
	access_incomplete_translations = allow_access


func set_framerate_limit(limit: int) -> void:
	assert(
		limit in VALID_FRAMERATE_LIMITS,
		"The framerate limit must be one of: %s" % [VALID_FRAMERATE_LIMITS],
	)
	framerate_limit = maxi(limit, 0)
	framerate_limit_changed.emit(framerate_limit)
