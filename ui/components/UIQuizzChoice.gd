class_name UIQuizzChoice
extends PanelContainer

const COLOR_WHITE_TRANSPARENT := Color(1.0, 1.0, 1.0, 0.0)

onready var _outline := $Outline as PanelContainer
onready var _question := $MarginContainer/ChoiceView/Question as Label
onready var _choices := $MarginContainer/ChoiceView/Choices as VBoxContainer
onready var _explanation := $MarginContainer/ResultView/Explanation as RichTextLabel
onready var _content := $MarginContainer/ChoiceView/Content as RichTextLabel
onready var _submit_button := $MarginContainer/ChoiceView/SubmitButton as Button

onready var _choice_view := $MarginContainer/ChoiceView as VBoxContainer
onready var _result_view := $MarginContainer/ResultView as VBoxContainer

onready var _tween := $Tween as Tween

var _quizz: QuizzChoice


func _ready() -> void:
	_submit_button.connect("pressed", self, "_test_answer")


func setup(quizz: QuizzChoice) -> void:
	_quizz = quizz
	if not is_inside_tree():
		yield(self, "ready")

	_question.text = _quizz.question

	_content.visible = not _quizz.content_bbcode.empty()
	_content.bbcode_text = _quizz.content_bbcode

	_explanation.bbcode_text = _quizz.explanation_bbcode

	var answer_options := _quizz.answer_options
	if _quizz.do_shuffle_answers:
		answer_options.shuffle()
	if _quizz.is_multiple_choice:
		for answer in answer_options:
			var button := CheckBox.new()
			button.text = answer
			_choices.add_child(button)
	else:
		var group := ButtonGroup.new()
		for answer in answer_options:
			var button := Button.new()
			button.toggle_mode = true
			button.text = answer
			button.group = group
			_choices.add_child(button)


func _test_answer() -> void:
	var answers := _get_answers()
	var result := _quizz._test_answer(answers)
	if not result.is_correct:
		_tween.stop_all()
		_outline.modulate = Color.white
		_tween.interpolate_property(
			_outline,
			"modulate",
			_outline.modulate,
			COLOR_WHITE_TRANSPARENT,
			0.8,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN,
			0.75
		)
		_tween.start()
	else:
		_result_view.show()
		_choice_view.hide()


# Returns an array of indices of selected answers
func _get_answers() -> Array:
	var answer_buttons := _choices.get_children()
	var first_button = answer_buttons[0]
	var answers := []
	if first_button is CheckBox:
		for button in answer_buttons:
			if button.pressed:
				answers.append(button.text)
	else:
		answers = [first_button.group.get_pressed_button().text]
	return answers
