class_name BaseQuizz
extends Resource

export var question := ""
export var content_bbcode := ""
export var hint := ""
export var explanation_bbcode := ""


class AnswerTestResult:
	var is_correct := false
	var help_message := ""


# Returns an error message
# @tags: virtual
func _test_answer(answer) -> AnswerTestResult:
	printerr("You didn't override the _is_answer_correct() method on the Quizz resource.")
	return AnswerTestResult.new()
