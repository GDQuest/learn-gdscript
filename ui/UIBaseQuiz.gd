class_name UIBaseQuiz
extends PanelContainer

signal quiz_passed
signal quiz_skipped

const ERROR_OUTLINE := preload("res://ui/theme/quiz_outline_error.tres")
const PASSED_OUTLINE := preload("res://ui/theme/quiz_outline_passed.tres")
const NEUTRAL_OUTLINE := preload("res://ui/theme/quiz_outline_neutral.tres")

const OUTLINE_FLASH_DURATION := 0.8
const OUTLINE_FLASH_DELAY := 0.75

export var test_quiz: Resource

var completed_before := false setget set_completed_before

onready var _outline := $Outline as PanelContainer
onready var _question := $MarginContainer/ChoiceView/QuizHeader/Question as Label
onready var _explanation := $MarginContainer/ResultView/Explanation as RichTextLabel
onready var _content := $MarginContainer/ChoiceView/Content as RichTextLabel
onready var _completed_before_icon := (
	$MarginContainer/ChoiceView/QuizHeader/CompletedBeforeIcon as TextureRect
)

onready var _choice_view := $MarginContainer/ChoiceView as VBoxContainer
onready var _result_view := $MarginContainer/ResultView as VBoxContainer

onready var _submit_button := $MarginContainer/ChoiceView/HBoxContainer/SubmitButton as Button
onready var _skip_button := $MarginContainer/ChoiceView/HBoxContainer/SkipButton as Button

onready var _result_label := $MarginContainer/ResultView/Label as Label
onready var _correct_answer_label := $MarginContainer/ResultView/CorrectAnswer as Label

onready var _tween := $Tween as Tween
onready var _help_message := $MarginContainer/ChoiceView/HelpMessage as Label

var _quiz: Quiz


func _ready() -> void:
	_completed_before_icon.visible = completed_before
	
	_submit_button.connect("pressed", self, "_test_answer")
	_skip_button.connect("pressed", self, "_show_answer", [false])


func setup(quiz: Quiz) -> void:
	_quiz = quiz

	if not is_inside_tree():
		yield(self, "ready")

	_question.text = _quiz.question

	_content.visible = not _quiz.content_bbcode.empty()
	_content.bbcode_text = TextUtils.bbcode_add_code_color(_quiz.content_bbcode)

	_explanation.visible = not _quiz.explanation_bbcode.empty()
	_explanation.bbcode_text = TextUtils.bbcode_add_code_color(_quiz.explanation_bbcode)


func set_completed_before(value: bool) -> void:
	completed_before = value

	if is_inside_tree():
		_completed_before_icon.visible = completed_before


# Virtual
func _get_answers() -> Array:
	return []


func _test_answer() -> void:
	var result: Quiz.AnswerTestResult = null
	_skip_button.disabled = false
	if _quiz is QuizChoice:
		result = _quiz.test_answer(_get_answers())
	else:
		# The input field quiz takes a single string as a test answer.
		result = _quiz.test_answer(_get_answers().back())
	_help_message.text = result.help_message
	_help_message.visible = not result.help_message.empty()
	_tween.stop_all()
	if not result.is_correct:
		_outline.modulate.a = 1.0
		_outline.add_stylebox_override("panel", ERROR_OUTLINE)

		_tween.interpolate_property(
			_outline,
			"modulate:a",
			_outline.modulate.a,
			0.0,
			OUTLINE_FLASH_DURATION,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN,
			OUTLINE_FLASH_DELAY
		)
		_tween.start()
	else:
		_show_answer()


func _show_answer(gave_correct_answer := true) -> void:
	_tween.stop_all()
	_outline.add_stylebox_override("panel", PASSED_OUTLINE if gave_correct_answer else NEUTRAL_OUTLINE)
	_outline.modulate.a = 1.0

	_result_view.show()
	_choice_view.hide()
	if gave_correct_answer:
		emit_signal("quiz_passed")
	else:
		if _quiz.get_answer_count() == 1:
			_result_label.text = "The answer was:"
		else:
			_result_label.text = "The answers were:"
		_correct_answer_label.show()
		_correct_answer_label.text = _quiz.get_correct_answer_string()
		emit_signal("quiz_skipped")
