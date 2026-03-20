class_name CourseIndex
extends RefCounted


func get_title() -> String:
	return _get_title()


func get_lessons_count() -> int:
	return _get_lessons_count()


func get_lesson_path(i: int) -> String:
	return _get_lesson_path(i)


func get_course_id() -> String:
	return _get_course_id()


func _get_course_id() -> String:
	return "empty_course"


func _get_lessons_count() -> int:
	return 0


func _get_title() -> String:
	return "Empty Course"


func _get_lesson_path(i: int) -> String:
	return ""
