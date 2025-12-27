class_name CourseProgress
extends Resource

# Course resource identifier.
@export var course_id := ""

# FIX: Tell Godot this is an array of LessonProgress objects
@export var lessons: Array[LessonProgress] = [] 

func _init() -> void:
	# In Godot 4, you don't necessarily need to reset these in _init 
	# if they are exported with defaults, but it doesn't hurt.
	pass

func reset() -> void:
	lessons = []
