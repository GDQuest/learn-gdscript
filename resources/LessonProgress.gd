## Lesson progress data, used for tracking and serialization.
class_name LessonProgress
extends Resource

## Lesson resource identifier.
@export var lesson_id: String = ""
## Flag that indicates that the user got to the bottom of the lesson and clicked on any practice.
@export var completed_reading: bool = false
## Identifiers of completed quiz resources.
@export var completed_quizzes: Array[String] = []
## Identifiers of completed practice resources.
@export var completed_practices: Array[String] = []


## Returns the number of completed quizzes for the given [param lesson].
func get_completed_quizzes_count(lesson: BBCodeParser.ParseNode) -> int:
	var quiz_count := BBCodeUtils.get_lesson_quiz_count(lesson)
	var completed := 0

	# We collect them beforehand so that we can clear the list as we go and ensure only
	# unique entries are counted.
	var available_quizzes: Array[String] = []
	for i in quiz_count:
		var quiz := BBCodeUtils.get_lesson_quiz(lesson, i)
		var quiz_id := BBCodeUtils.get_quiz_id(quiz)
		available_quizzes.push_back(quiz_id)

	for quiz_id in completed_quizzes:
		if not available_quizzes.has(quiz_id):
			continue

		available_quizzes.erase(quiz_id)
		completed += 1

	return completed


## Returns the number of completed practices for the given [param lesson].
func get_completed_practices_count(lesson: BBCodeParser.ParseNode) -> int:
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
	var completed := 0

	# We collect them beforehand so that we can clear the list as we go and ensure only
	# unique entries are counted.
	var available_practices: Array[String] = []
	for i in practice_count:
		var practice := BBCodeUtils.get_lesson_practice(lesson, i)
		var practice_id := BBCodeUtils.get_practice_id(practice)
		available_practices.push_back(practice_id)

	for practice_id in completed_practices:
		if not available_practices.has(practice_id):
			continue

		available_practices.erase(practice_id)
		completed += 1

	return completed
