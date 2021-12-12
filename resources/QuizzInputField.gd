# Quizz based on an editable text field in which the user types a number or text.
class_name QuizzInputField
extends BaseQuizz

# One of the TYPE_* constants.
var type := -1
var valid_answer setget set_valid_answer


func test_answer(answer: String) -> AnswerTestResult:
	var result := AnswerTestResult.new()
	answer = answer.strip_edges()
	match type:
		TYPE_INT:
			assert(valid_answer is int)
			if not answer.is_valid_integer():
				result.help_message = "You need to type a whole number for this answer. Example: 42"
			result.is_correct = int(answer) == valid_answer
		TYPE_REAL:
			assert(valid_answer is float)
			if not answer.is_valid_float():
				result.help_message = 'You need to type a decimal for this answer. Use a "." to separate the decimal part. Example: 3.14'
			result.is_correct = float(answer) == valid_answer
		TYPE_STRING:
			assert(valid_answer is String)
			# We should test exact strings because some answers will be code and
			# require exact capitalization.
			result.is_correct = answer == valid_answer
		_:
			printerr("Unsupported answer type.")
	return result


func set_valid_answer(value) -> void:
	valid_answer = value
	if type == -1:
		type = typeof(value)
