class_name UIQuizChoice
extends UIBaseQuiz

const OPTION_FONT := preload("res://ui/theme/fonts/font_text.tres")
const OPTION_SELECTED_FONT := preload("res://ui/theme/fonts/font_text_bold.tres")

onready var _choices := $MarginContainer/ChoiceView/Answers as VBoxContainer


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
		for answer in answer_options:
			var button := CheckBox.new()
			button.text = answer
			button.add_font_override("font", OPTION_FONT)
			_choices.add_child(button)
			button.connect("toggled", self, "_on_option_button_toggled", [button])
	else:
		var group := ButtonGroup.new()
		for answer in answer_options:
			var button := Button.new()
			button.toggle_mode = true
			button.text = answer
			button.group = group
			button.add_font_override("font", OPTION_FONT)
			_choices.add_child(button)
			button.connect("toggled", self, "_on_option_button_toggled", [button])


# Returns an array of indices of selected answers
func _get_answers() -> Array:
	var answers := []
	var quiz_choice = (_quiz as QuizChoice)
	if not quiz_choice:
		return answers
	
	if quiz_choice.is_multiple_choice:
		for button in _choices.get_children():
			if button.pressed:
				answers.append(button.text)
	else:
		for button in _choices.get_children():
			if button.pressed:
				answers.append(button.text)
				break
	
	return answers


func _on_option_button_toggled(pressed: bool, button: Button) -> void:
	button.add_font_override("font", OPTION_SELECTED_FONT if pressed else OPTION_FONT)
