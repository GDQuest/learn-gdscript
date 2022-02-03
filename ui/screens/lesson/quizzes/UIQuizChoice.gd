class_name UIQuizChoice
extends UIBaseQuiz

const QuizAnswerButtonScene := preload("res://ui/screens/lesson/quizzes/QuizAnswerButton.tscn")


onready var _choices := $ClipContentBoundary/ChoiceContainer/ChoiceView/Answers as VBoxContainer


func _ready() -> void:
	if test_quiz and test_quiz is Quiz:
		setup(test_quiz)


func setup(quiz: Quiz) -> void:
	.setup(quiz)
	var quiz_choice = (_quiz as QuizChoice)
	if not quiz_choice:
		return

	var answer_options: Array = quiz_choice.answer_options.duplicate()
	if quiz_choice.do_shuffle_answers:
		answer_options.shuffle()

	if quiz_choice.is_multiple_choice:
		_question.bbcode_text += " [i]" + tr("(select all that apply)") + "[/i]"

	for answer in answer_options:
		var button = QuizAnswerButtonScene.instance()
		button.setup(answer, quiz_choice.is_multiple_choice)
		_choices.add_child(button)


# Returns an array of indices of selected answers
func _get_answers() -> Array:
	var answers := []
	var quiz_choice = (_quiz as QuizChoice)
	if not quiz_choice:
		return answers

	for button in _choices.get_children():
		var answer = button.get_answer()
		if answer:
			answers.append(answer)
			if not quiz_choice.is_multiple_choice:
				break

	return answers
