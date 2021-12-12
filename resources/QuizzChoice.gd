# Quizz based on a single or multiple choice form.
class_name QuizzChoice
extends Quizz

const ERROR_NO_VALID_ANSWERS := "No valid answers set for QuizzChoice resource, can't test answers."

export var answer_options := []
export var valid_answers := []
export var is_multiple_choice := false
export var do_shuffle_answers := true


func _test_answer(answers: Array) -> AnswerTestResult:
	assert(not valid_answers.empty(), ERROR_NO_VALID_ANSWERS)
	var result := AnswerTestResult.new()
	result.is_correct = answers.size() == valid_answers.size()
	if result.is_correct:
		for answer in answers:
			if not answer in valid_answers:
				result.is_correct = false
				break
	return result
