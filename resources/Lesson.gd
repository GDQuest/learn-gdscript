# Base resource for a lesson. Stores the lesson's content as an array of content
# blocks and a list of practices to complete the lesson.
class_name Lesson
extends Resource

@export var title := ""
# Array of content blocks to display sequentially in the lesson. The blocks in
# question can be plain text and image ContentBlock, but also other resources
# like quizzes.
@export var content_blocks: Array
# Array[Practice]
@export var practices: Array


func _init() -> void:
	content_blocks = []
	practices = []


func get_practice_index(practice_id: String) -> int:
	for i in range(practices.size()):
		var practice: Practice = practices[i]
		if practice.practice_id == practice_id:
			return i
	return -1


func get_quizzes() -> Array:
	var quizzes := []
	
	for content_item in content_blocks:
		if content_item is Quiz:
			quizzes.append(content_item)
	
	return quizzes


func get_quizzes_count() -> int:
	var total_quizzes := 0
	for content_item in content_blocks:
		if content_item is Quiz:
			total_quizzes += 1

	return total_quizzes
