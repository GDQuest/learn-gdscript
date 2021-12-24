class_name LessonProgress
extends Resource

# Lesson resource identifier.
export var lesson_id := ""
# Set when the user got to the bottom of the lesson and clicked on any practice.
export var completed_reading := false
# Indices of completed quizzes (following the order quizzes appear in the lesson).
export var completed_quizzes := [] # Array of int
# Identifiers of completed practice resources.
export var completed_practices := [] # Array of String

func _init() -> void:
	completed_quizzes = []
	completed_practices = []


func get_completed_quizzes_count(quizzes_count: int) -> int:
	var completed := 0
	
	# We will use this array to track the indices we have already handled and ensure
	# only unique entries are counted.
	var accounted_quizzes := []
	var max_quiz_index := quizzes_count - 1
	
	for quiz_index in completed_quizzes:
		if quiz_index >= 0 and quiz_index <= max_quiz_index and not accounted_quizzes.has(quiz_index):
			completed += 1
			accounted_quizzes.append(quiz_index)

	return completed


func get_completed_practices_count(practices: Array) -> int:
	var completed := 0
	
	# We collect them beforehand so that we can clear the list as we go and ensure only
	# unique entries are counted.
	var available_practices := []
	for practice_data in practices:
		available_practices.append(practice_data.resource_path)
	
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
