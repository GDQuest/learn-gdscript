class_name UIQuizChoice
extends UIBaseQuiz

const QuizAnswerButtonScene := preload("res://ui/screens/lesson/quizzes/QuizAnswerButton.tscn")
const ERROR_NO_VALID_ANSWERS := "No valid answers set for QuizChoice resource, can't test answers."


onready var _choices := $ClipContentBoundary/ChoiceContainer/ChoiceView/Answers as VBoxContainer


func _ready() -> void:
	pass
	#if test_quiz and test_quiz is Quiz:
	#	setup(test_quiz)


func setup(quiz: BBCodeParser.ParseNode) -> void:
	.setup(quiz)
	if not quiz.tag == BBCodeParserData.Tag.QUIZ_CHOICE:
		return

	var answer_options: Array = _quiz_data.answers.duplicate()
	if _quiz_data.shuffle:
		answer_options.shuffle()

	var is_multiple_choice := _quiz_data.multiple
	if is_multiple_choice:
		_question.bbcode_text += " [i]" + tr("(select all that apply)") + "[/i]"

	for answer in answer_options:
		var button = QuizAnswerButtonScene.instance()
		button.setup(answer, is_multiple_choice)
		_choices.add_child(button)


# Returns an array of indices of selected answers
func _get_answers() -> Array:
	var answers := []
	if _quiz.tag != BBCodeParserData.Tag.QUIZ_CHOICE:
		return answers

	var is_multiple_choice := _quiz_data.multiple
	for button in _choices.get_children():
		var answer = button.get_answer()
		if answer:
			answers.append(answer)
			if not is_multiple_choice:
				break

	return answers


func _test_answer_against_quiz(answers: Array) -> AnswerTestResult:
	assert(not _quiz_data.valid_answers.empty(), ERROR_NO_VALID_ANSWERS)
	var result := AnswerTestResult.new()
	result.is_correct = answers.size() == _quiz_data.valid_answers.size()
	if result.is_correct:
		for answer in answers:
			if not answer in _quiz_data.valid_answers:
				result.is_correct = false
				break
	return result
