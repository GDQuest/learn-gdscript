## Course progress data, used for tracking and serialization.
class_name CourseProgress
extends Resource

## Course resource identifier.
@export var course_id: String = ""
## Lesson progression data.
@export var lessons: Array[LessonProgress] = []


func reset() -> void:
	lessons = []
