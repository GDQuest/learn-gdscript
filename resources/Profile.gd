class_name Profile
extends Resource

signal progress_changed(exercise_name, progress)
signal scroll_sensitivity_changed(new_value)
signal framerate_limit_changed(new_value)

const VALID_FRAMERATE_LIMITS := [0, 30, 60]
const URL_GODOT_DOCS_REF = "ref=godot-docs"

# General profile details
@export var player_name: String = ""

# Study progression (across multiple courses)
# Typed arrays are better in Godot 4
@export var study_progression: Array[Resource] = []
@export var last_started_lesson: Dictionary[String, String] = {}
@export var last_visible_lesson_block: Dictionary[String, Dictionary] = {}
@export var is_sponsored_profile := true

# User settings
@export var language := "en"
@export var font_size_scale: float = 0
@export var lower_contrast := false
@export var dyslexia_font := false

@export var scroll_sensitivity: float = 1.0:
	set(value):
		scroll_sensitivity = max(value, 0.1)
		scroll_sensitivity_changed.emit(scroll_sensitivity)

@export var framerate_limit: int = 60:
	set(value):
		assert(
			value in VALID_FRAMERATE_LIMITS,
			"The framerate limit must be one of: " + str(VALID_FRAMERATE_LIMITS)
		)
		framerate_limit = value
		framerate_limit_changed.emit(framerate_limit)

func _init() -> void:
	if study_progression == null:
		study_progression = []
	if last_started_lesson == null:
		last_started_lesson = {}

	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		if window:
			var browser_url: String = str(JavaScriptBridge.eval("window.location.href"))
			is_sponsored_profile = browser_url.find(URL_GODOT_DOCS_REF) == -1

func save() -> void:
	if resource_path.is_empty():
		push_error("Cannot save a file without a filename, set resource_path first.")
		return
	ResourceSaver.save(self, resource_path)
	take_over_path(resource_path)

func get_or_create_course(course_id: String) -> CourseProgress:
	for item in study_progression:
		var course_p := item as CourseProgress
		
		if course_p and course_p.course_id == course_id:
			return course_p

	var new_course_progress := CourseProgress.new()
	new_course_progress.course_id = course_id
	study_progression.append(new_course_progress)
	save()
	return new_course_progress


func get_or_create_lesson(course_id: String, lesson_id: String) -> LessonProgress:
	var course_progress := get_or_create_course(course_id)
	
	for item in course_progress.lessons:
		var lesson_p := item as LessonProgress
		
		if lesson_p and lesson_p.lesson_id == lesson_id:
			return lesson_p

	var new_lesson_progress := LessonProgress.new()
	new_lesson_progress.lesson_id = lesson_id
	course_progress.lessons.append(new_lesson_progress)
	save()
	return new_lesson_progress


func set_lesson_reading_block(course_id: String, lesson_id: String, block_id: String) -> void:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)

	if not lesson_progress.completed_blocks.has(block_id):
		lesson_progress.completed_blocks.append(block_id)

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
	var _course_progress := get_or_create_course(course_id)
	var _lesson_progress := get_or_create_lesson(course_id, lesson_id)
	last_started_lesson[course_id] = lesson_id
	save()


func get_last_started_lesson(course_id: String) -> String:
	var _course_progress := get_or_create_course(course_id)
	var lesson_id: String = last_started_lesson.get(course_id, "")

	if lesson_id.is_empty():
		return ""

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
