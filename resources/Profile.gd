class_name Profile
extends Resource

signal progress_changed(exercise_name, progress)

# General profile details
export var player_name := ""
# Study progression (across multiple courses)
export var study_progression := []
export var last_started_lesson := {}
# User settings
export var font_size_scale := 0


func _init() -> void:
	study_progression = []
	last_started_lesson = {}


func save() -> void:
	if resource_path.empty():
		push_error("Cannot save a file without a filename, set resource_path first.")
		return
	ResourceSaver.save(resource_path, self)
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


func set_lesson_reading_completed(course_id: String, lesson_id: String, completed: bool) -> void:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	lesson_progress.completed_reading = completed
	save()


func is_lesson_reading_completed(course_id: String, lesson_id: String) -> bool:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_progress.completed_reading


func set_lesson_quiz_completed(course_id: String, lesson_id: String, quiz_index: int, completed: bool) -> void:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	
	var quiz_listed := lesson_progress.completed_quizzes.has(quiz_index)
	if completed and not quiz_listed:
		lesson_progress.completed_quizzes.append(quiz_index)
	elif not completed and quiz_listed:
		lesson_progress.completed_quizzes.erase(quiz_index)
	
	save()


func is_lesson_quiz_completed(course_id: String, lesson_id: String, quiz_index: int) -> bool:
	var lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_progress.completed_quizzes.has(quiz_index)


func set_lesson_practice_completed(course_id: String, lesson_id: String, practice_id: String, completed: bool) -> void:
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
	
	if lesson_id.empty():
		return ""
	
	# Ensure we have some data for the lesson, if we didn't have it before.
	var _lesson_progress := get_or_create_lesson(course_id, lesson_id)
	return lesson_id
