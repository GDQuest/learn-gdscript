class_name CourseProgress
extends Resource

# Course resource identifier.
@export var course_id := ""
# Lesson progression data.
@export var lessons := [] # Array of LessonProgress

func _init() -> void:
	lessons = []


func reset() -> void:
	lessons = []
