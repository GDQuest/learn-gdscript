class_name UIQuizzInputField
extends PanelContainer

const COLOR_WHITE_TRANSPARENT := Color(1.0, 1.0, 1.0, 0.0)

onready var _outline := $Outline as PanelContainer
onready var _question := $MarginContainer/ChoiceView/Question as Label
onready var _explanation := $MarginContainer/ResultView/Explanation as RichTextLabel
onready var _content := $MarginContainer/ChoiceView/Content as RichTextLabel

onready var _submit_button := $MarginContainer/ChoiceView/HBoxContainer/SubmitButton as Button
onready var _line_edit := $MarginContainer/ChoiceView/HBoxContainer/LineEdit as LineEdit

onready var _choice_view := $MarginContainer/ChoiceView as VBoxContainer
onready var _result_view := $MarginContainer/ResultView as VBoxContainer

onready var _tween := $Tween as Tween
onready var _help_message := $MarginContainer/ChoiceView/HelpMessage as Label

var _quizz: QuizzInputField


func _ready() -> void:
	_submit_button.connect("pressed", self, "_test_answer")
	_line_edit.connect("text_entered", self, "_test_answer")


func setup(quizz: QuizzInputField) -> void:
	_quizz = quizz
	if not is_inside_tree():
		yield(self, "ready")

	_question.text = _quizz.question

	_content.visible = not _quizz.content_bbcode.empty()
	_content.bbcode_text = _quizz.content_bbcode

	_explanation.visible = not _quizz.explanation_bbcode.empty()
	_explanation.bbcode_text = _quizz.explanation_bbcode


func _test_answer() -> void:
	var result := _quizz.test_answer(_line_edit.text)
	_help_message.text = result.help_message
	_help_message.visible = not result.help_message.empty()
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
