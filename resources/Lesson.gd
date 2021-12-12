# Base resource for a lesson. Stores the lesson's content as an array of content
# blocks and a list of practices to complete the lesson.
class_name Lesson
extends Resource

export var title := ""
# Array[ContentBlock]
export var content_blocks: Array
# Array[Practice]
export var practices: Array


func _init() -> void:
	content_blocks = []
	practices = []
