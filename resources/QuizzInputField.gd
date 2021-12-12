# Quizz based on an editable text field in which the user types a number or text.
class_name QuizzInputField
extends BaseQuizz

enum Type { NUMBER_INT, NUMBER_FLOAT, STRING }

var type: int = Type.STRING
var valid_answer


func _is_answer_correct(answer: String) -> AnswerTestResult:
	var result := AnswerTestResult.new()
	answer = answer.strip_edges()
	match type:
		Type.NUMBER_INT:
			assert(valid_answer is int)
			if not answer.is_valid_integer():
				result.help_message = "You need to type a whole number for this answer. Example: 42"
			result.is_correct = int(answer) == valid_answer
		Type.NUMBER_FLOAT:
			assert(valid_answer is float)
			if not answer.is_valid_float():
				result.help_message = 'You need to type a decimal for this answer. Use a "." to separate the decimal part. Example: 3.14'
			result.is_correct = float(answer) == valid_answer
		Type.STRING:
			assert(valid_answer is String)
			# We should test exact strings because some answers will be code and
			# require exact capitalization.
			result.is_correct = answer == valid_answer
		_:
			printerr("Unsupported answer type.")
	return result
