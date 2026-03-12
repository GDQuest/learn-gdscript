class_name UIQuizInputField
extends UIBaseQuiz

onready var _line_edit := $ClipContentBoundary/ChoiceContainer/ChoiceView/Answers/LineEdit as LineEdit


func _ready() -> void:
	_line_edit.connect("text_entered", self, "_test_answer")


func _get_answers() -> Array:
	return [_line_edit.text]


func _test_answer_against_quiz(answers: Array) -> AnswerTestResult:
	var parsed_answers := BBCodeUtils.get_quiz_choices(_quiz)
	var parsed_answer: String = parsed_answers[0]
	var type := TYPE_STRING
	if parsed_answer.is_valid_float():
		type = TYPE_REAL
	elif parsed_answer.is_valid_integer():
		type = TYPE_INT
	
	var result := AnswerTestResult.new()
	var answer: String = answers[0]
	answer = answer.strip_edges()
	
	match type:
		TYPE_INT:
			if not answer.is_valid_integer():
				result.help_message = tr("You need to type a whole number for this answer. Example: 42")
			result.is_correct = int(answer) == int(parsed_answer)
		TYPE_REAL:
			if not answer.is_valid_float():
				result.help_message = tr('You need to type a decimal for this answer. Use a "." to separate the decimal part. Example: 3.14')
			result.is_correct = float(answer) == float(parsed_answer)
		TYPE_STRING:
			# We should test exact strings because some answers will be code and
			# require exact capitalization.
			result.is_correct = answer == parsed_answer
		_:
			printerr("Unsupported answer type.")
	return result
