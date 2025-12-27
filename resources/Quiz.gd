# Base class for specific kinds of interactive quizzes.
class_name Quiz
extends Resource

# Uniquely identifies the quiz resource.
@export var quiz_id := ""

@export var question := ""
@export var content_bbcode := ""
@export var hint := ""
@export var explanation_bbcode := ""


class AnswerTestResult:
	var is_correct := false
	var help_message := ""


# Returns an error message
# @tags: virtual
func test_answer(_answer) -> AnswerTestResult:
	printerr("You didn't override the _is_answer_correct() method on the Quiz resource.")
	return AnswerTestResult.new()


func get_correct_answer_string() -> String:
	return ""


func get_answer_count() -> int:
	return 1
