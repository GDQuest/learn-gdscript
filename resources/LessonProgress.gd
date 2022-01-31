class_name LessonProgress
extends Resource

# Lesson resource identifier.
export var lesson_id := ""
# Identifiers of reached content blocks.
export var completed_blocks := [] # Array of String
# Set when the user got to the bottom of the lesson and clicked on any practice.
export var completed_reading := false
# Identifiers of completed quiz resources.
export var completed_quizzes := [] # Array of String
# Identifiers of completed practice resources.
export var completed_practices := [] # Array of String

func _init() -> void:
	completed_blocks = []
	completed_quizzes = []
	completed_practices = []


func get_completed_blocks_count(blocks: Array) -> int:
	var completed := 0

	# We collect them beforehand so that we can clear the list as we go and ensure only
	# unique entries are counted.
	var available_blocks := []
	for block_data in blocks:
		if block_data is Quiz:
			available_blocks.append(block_data.quiz_id)
		else:
			available_blocks.append(block_data.content_id)

	for block_id in completed_blocks:
		var matched_id := ""

		for block_path in available_blocks:
			if block_path == block_id:
				matched_id = block_path
				break

		if not matched_id.empty():
			available_blocks.erase(matched_id)
			completed += 1

	return completed


func get_completed_quizzes_count(quizzes: Array) -> int:
	var completed := 0

	# We collect them beforehand so that we can clear the list as we go and ensure only
	# unique entries are counted.
	var available_quizzes := []
	for quiz_data in quizzes:
		available_quizzes.append(quiz_data.quiz_id)

	for quiz_id in completed_quizzes:
		var matched_id := ""

		for quiz_path in available_quizzes:
			if quiz_path == String(quiz_id): # Can be an int from old pre-beta versions.
				matched_id = quiz_path
				break

		if not matched_id.empty():
			available_quizzes.erase(matched_id)
			completed += 1

	return completed


func get_completed_practices_count(practices: Array) -> int:
	var completed := 0

	# We collect them beforehand so that we can clear the list as we go and ensure only
	# unique entries are counted.
	var available_practices := []
	for practice_data in practices:
		available_practices.append(practice_data.practice_id)

	for practice_id in completed_practices:
		var matched_id := ""

		for practice_path in available_practices:
			if practice_path == practice_id:
				matched_id = practice_path
				break

		if not matched_id.empty():
			available_practices.erase(matched_id)
			completed += 1

	return completed
