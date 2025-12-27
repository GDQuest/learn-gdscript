# Quiz based on a single or multiple choice form.
# The class is set to tool mode to use it in the Course Builder plugin.
@tool
class_name QuizChoice
extends Quiz

signal choice_type_changed(is_multiple_choice)

const ERROR_NO_VALID_ANSWERS := "No valid answers set for QuizChoice resource, can't test answers."

@export var answer_options: Array[String] = []
@export var valid_answers: Array[String] = []
@export var is_multiple_choice: bool = true:
	set(value):
		set_is_multiple_choice(value)
@export var do_shuffle_answers: bool = true


# We use the constructor to reset arrays and avoid a bug where creating a new
# QuizChoice references the answer_options and valid_answers of the previously
# created resource.
func _init() -> void:
	answer_options = []
	valid_answers = []
	is_multiple_choice = true
	do_shuffle_answers = true


func test_answer(answers: Array) -> AnswerTestResult:
	assert(not valid_answers.is_empty(), ERROR_NO_VALID_ANSWERS)
	var result := AnswerTestResult.new()
	result.is_correct = answers.size() == valid_answers.size()
	if result.is_correct:
		for answer in answers:
			if not answer in valid_answers:
				result.is_correct = false
				break
	return result


func set_is_multiple_choice(value: bool) -> void:
	if is_multiple_choice == value:
		return
	is_multiple_choice = value
	choice_type_changed.emit(is_multiple_choice)


func get_correct_answer_string() -> String:
	var answer_count := valid_answers.size()
	var string := ""
	if answer_count == 1:
		string = valid_answers.back()
	else:
		# We want a string with the form "a, b, and c"
		var index := 0
		var separator := ", "
		for answer in valid_answers:
			string += answer
			if index < answer_count - 1:
				string += separator
			if index == answer_count - 2:
				string += " and "
			index += 1
	return string


func get_answer_count() -> int:
	return valid_answers.size()
