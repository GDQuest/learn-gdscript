class_name UIBaseQuiz
extends PanelContainer

signal quiz_passed
signal quiz_skipped

const ERROR_OUTLINE := preload("res://ui/theme/quiz_outline_error.tres")
const PASSED_OUTLINE := preload("res://ui/theme/quiz_outline_passed.tres")
const NEUTRAL_OUTLINE := preload("res://ui/theme/quiz_outline_neutral.tres")

const OUTLINE_FLASH_DURATION := 0.8
const OUTLINE_FLASH_DELAY := 0.75
const ERROR_SHAKE_TIME := 0.5
const ERROR_SHAKE_SIZE := 20
const FADE_IN_TIME := 0.3
const FADE_OUT_TIME := 0.3
const SIZE_CHANGE_TIME := 0.5

export var test_quiz: Resource

var completed_before := false setget set_completed_before

onready var _outline := $Outline as PanelContainer
onready var _question := $ClipContentBoundary/ChoiceContainer/ChoiceView/QuizHeader/Question as RichTextLabel
onready var _explanation := $ClipContentBoundary/ResultContainer/ResultView/Explanation as RichTextLabel
onready var _content := $ClipContentBoundary/ChoiceContainer/ChoiceView/Content as RichTextLabel
onready var _completed_before_icon := (
	$ClipContentBoundary/ChoiceContainer/ChoiceView/QuizHeader/CompletedBeforeIcon as TextureRect
)

onready var _choice_container := $ClipContentBoundary/ChoiceContainer as MarginContainer
onready var _result_container := $ClipContentBoundary/ResultContainer as MarginContainer

onready var _submit_button := $ClipContentBoundary/ChoiceContainer/ChoiceView/HBoxContainer/SubmitButton as Button
onready var _skip_button := $ClipContentBoundary/ChoiceContainer/ChoiceView/HBoxContainer/SkipButton as Button

onready var _result_label := $ClipContentBoundary/ResultContainer/ResultView/Label as Label
onready var _correct_answer_label := $ClipContentBoundary/ResultContainer/ResultView/CorrectAnswer as Label

onready var _error_tween := $ErrorTween as Tween
onready var _size_tween := $SizeTween as Tween
onready var _help_message := $ClipContentBoundary/ChoiceContainer/ChoiceView/HelpMessage as Label

var _quiz: Quiz
var _shake_pos: float = 0
# Used for animating size changes
var _previous_rect_size := rect_size
var _next_rect_size := Vector2.ZERO
var _percent_transformed := 0.0
var _animating_hint := false


func _ready() -> void:
	_completed_before_icon.visible = completed_before

	_submit_button.connect("pressed", self, "_test_answer")
	_skip_button.connect("pressed", self, "_show_answer", [false])
	connect("item_rect_changed", self, "_on_item_rect_changed")
	
	_help_message.connect("visibility_changed", self, "_on_help_message_visibility_changed")
	_choice_container.connect("minimum_size_changed", self, "_on_choice_container_minimum_size_changed")
	_result_container.connect("minimum_size_changed", self, "_on_result_container_minimum_size_changed")
	
	_size_tween.connect("tween_step", self, "_on_size_tween_step")
	_size_tween.connect("tween_completed", self, "_on_size_tween_completed")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(quiz: Quiz) -> void:
	_quiz = quiz

	if not is_inside_tree():
		yield(self, "ready")

	_question.bbcode_text = "[b]" + tr(_quiz.question) + "[/b]"

	_content.visible = not _quiz.content_bbcode.empty()
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_content.bbcode_text = TextUtils.bbcode_add_code_color(tr(_quiz.content_bbcode.replace("\r\n", "\n")))

	_explanation.visible = not _quiz.explanation_bbcode.empty()
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_explanation.bbcode_text = TextUtils.bbcode_add_code_color(tr(_quiz.explanation_bbcode.replace("\r\n", "\n")))


func set_completed_before(value: bool) -> void:
	completed_before = value

	if is_inside_tree():
		_completed_before_icon.visible = completed_before


func _update_labels() -> void:
	if not _quiz:
		return
	
	_question.bbcode_text = "[b]" + tr(_quiz.question) + "[/b]"
	
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_content.bbcode_text = TextUtils.bbcode_add_code_color(tr(_quiz.content_bbcode.replace("\r\n", "\n")))
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_explanation.bbcode_text = TextUtils.bbcode_add_code_color(tr(_quiz.explanation_bbcode.replace("\r\n", "\n")))


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
	_error_tween.stop_all()
	if not result.is_correct:
		_outline.modulate.a = 1.0
		_outline.add_stylebox_override("panel", ERROR_OUTLINE)

		rect_position.y = _shake_pos
		_error_tween.interpolate_property(
			self,
			"rect_position:y",
			_shake_pos + ERROR_SHAKE_SIZE,
			_shake_pos,
			ERROR_SHAKE_TIME,
			Tween.TRANS_ELASTIC,
			Tween.EASE_OUT
		)
		_error_tween.interpolate_property(
			_outline,
			"modulate:a",
			_outline.modulate.a,
			0.0,
			OUTLINE_FLASH_DURATION,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN,
			OUTLINE_FLASH_DELAY
		)
		_error_tween.start()
	else:
		_show_answer()


func _show_answer(gave_correct_answer := true) -> void:
	_error_tween.stop_all()
	_outline.add_stylebox_override("panel", PASSED_OUTLINE if gave_correct_answer else NEUTRAL_OUTLINE)
	_outline.modulate.a = 1.0


	_result_container.show()
	_change_rect_size_to(_result_container.rect_size)
	
	#Hiding choice view upon completion of the following tween
	_size_tween.interpolate_property(
		_choice_container,
		"modulate:a",
		1,
		0,
		FADE_OUT_TIME
	)
	
	_size_tween.interpolate_property(
		_result_container,
		"modulate:a",
		0,
		1,
		FADE_IN_TIME,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT,
		FADE_OUT_TIME
	)
	
	_size_tween.start()
	
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

func _change_rect_size_to(size: Vector2, instant := false) -> void:
	_size_tween.stop_all()
	
	if instant:
		rect_min_size = size
		return
	
	_previous_rect_size = rect_min_size
	_next_rect_size = size
	_percent_transformed = 0.0
	
	_size_tween.interpolate_property(
		self,
		"_percent_transformed",
		0.0,
		1.0,
		SIZE_CHANGE_TIME,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	
	_size_tween.start()

func _on_item_rect_changed() -> void:
	if not _error_tween.is_active() or _error_tween.tell() > ERROR_SHAKE_TIME:
		_shake_pos = rect_position.y

	if _choice_container.rect_size.x < rect_size.x:
		_choice_container.rect_size.x = rect_size.x
	if _result_container.rect_size.x < rect_size.x:
		_result_container.rect_size.x = rect_size.x

func _on_help_label_visibility_changed() -> void:
	_animating_hint = true

func _on_choice_container_minimum_size_changed() -> void:
	if _choice_container.rect_size.y > _choice_container.get_combined_minimum_size().y:
		_choice_container.rect_size.y = _choice_container.get_combined_minimum_size().y
	
	if not _result_container.visible:
		# If not animating the hint, just resize normally.
		_change_rect_size_to(_choice_container.rect_size, !_animating_hint)

func _on_result_container_minimum_size_changed() -> void:
	if _result_container.rect_size.y > _result_container.get_combined_minimum_size().y:
		_result_container.rect_size.y = _result_container.get_combined_minimum_size().y
	
	if _result_container.visible:
		_change_rect_size_to(_result_container.rect_size)

func _on_size_tween_step(object: Object, key: NodePath, _elapsed: float, _value: Object) -> void:
	if object == self and key == ":_percent_transformed" and _next_rect_size != Vector2.ZERO:
		var new_size := _previous_rect_size
		var difference := _next_rect_size - _previous_rect_size
		new_size += difference * _percent_transformed
		rect_min_size = new_size

func _on_size_tween_completed(object: Object, key: NodePath) -> void:
	if object == self and key == ":_percent_transformed":
		_next_rect_size = Vector2.ZERO
		_animating_hint = false
	
	# To avoid the buttons being clickable after choice view is gone.
	if object == _choice_container and key == ":modulate:a":
		_choice_container.hide()
