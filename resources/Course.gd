# Contains a series of lessons to tackle sequentially.
class_name Course
extends Resource

@export var title := ""
# Array[Lesson]
@export var lessons: Array


func _init() -> void:
	lessons = []
