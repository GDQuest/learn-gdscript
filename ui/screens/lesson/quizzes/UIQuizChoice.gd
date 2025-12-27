class_name UIQuizChoice
extends UIBaseQuiz

const QuizAnswerButtonScene := preload("res://ui/screens/lesson/quizzes/QuizAnswerButton.tscn")

@onready var _choices := $ClipContentBoundary/ChoiceContainer/ChoiceView/Answers as VBoxContainer

func _ready() -> void:
	var q := test_quiz as Quiz
	if q != null:
		setup(q)

func setup(quiz: Quiz) -> void:
	super.setup(quiz)
	var quiz_choice := _quiz as QuizChoice
	if quiz_choice == null:
		return


	var answer_options: Array = quiz_choice.answer_options.duplicate()
	if quiz_choice.do_shuffle_answers:
		answer_options.shuffle()

	if quiz_choice.is_multiple_choice:
		_question.append_text(" [i]" + tr("(select all that apply)") + "[/i]")

	for answer in answer_options:
		var button := QuizAnswerButtonScene.instantiate()
		button.call("setup", answer, quiz_choice.is_multiple_choice)
		_choices.add_child(button)

# Returns an array of indices of selected answers
func _get_answers() -> Array:
	var answers := []
	var quiz_choice = (_quiz as QuizChoice)
	if not quiz_choice:
		return answers

	for button in _choices.get_children():
		var answer: String = button.call("get_answer")
		if not answer.is_empty():
			answers.append(answer)
			if not quiz_choice.is_multiple_choice:
				break

	return answers
