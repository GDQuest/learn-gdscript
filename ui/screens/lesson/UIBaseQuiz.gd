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

@export var test_quiz: Resource

var completed_before: bool = false:
	set(value):
		set_completed_before(value)

@onready var _outline := $Outline as PanelContainer
@onready var _question: RichTextLabel = $ClipContentBoundary/ChoiceContainer/Question
@onready var _explanation: RichTextLabel = $ClipContentBoundary/ChoiceContainer/Explanation
@onready var _content: RichTextLabel = $ClipContentBoundary/ChoiceContainer/Content
@onready var _completed_before_icon := (
	$ClipContentBoundary/ChoiceContainer/ChoiceView/QuizHeader/CompletedBeforeIcon as TextureRect
)

@onready var _choice_container := $ClipContentBoundary/ChoiceContainer as MarginContainer
@onready var _result_container := $ClipContentBoundary/ResultContainer as MarginContainer

@onready var _submit_button := $ClipContentBoundary/ChoiceContainer/ChoiceView/HBoxContainer/SubmitButton as Button
@onready var _skip_button := $ClipContentBoundary/ChoiceContainer/ChoiceView/HBoxContainer/SkipButton as Button

@onready var _result_label := $ClipContentBoundary/ResultContainer/ResultView/Label as Label
@onready var _correct_answer_label := $ClipContentBoundary/ResultContainer/ResultView/CorrectAnswer as Label

# TODO: Might be good to remove those Tween
var _error_tween: Tween
var _size_tween: Tween

@onready var _help_message := $ClipContentBoundary/ChoiceContainer/ChoiceView/HelpMessage as Label

var _quiz: Quiz
var _shake_pos: float = 0
# Used for animating size changes
var _previous_rect_size: Vector2 = Vector2.ZERO
var _next_rect_size := Vector2.ZERO
var _percent_transformed := 0.0
var _animating_hint := false


# Required for Godot 4 signal connection.
# If visibility change handling is not needed, remove both this method
# and the corresponding signal connection.
func _on_help_message_visibility_changed() -> void:
	pass


func _ready() -> void:
	_completed_before_icon.visible = completed_before

	_submit_button.pressed.connect(_test_answer)
	_skip_button.pressed.connect(_show_answer.bind(false))
	item_rect_changed.connect(_on_item_rect_changed)
	
	_help_message.visibility_changed.connect(
		_on_help_message_visibility_changed)
	_choice_container.minimum_size_changed.connect(
		_on_choice_container_minimum_size_changed)
	_result_container.minimum_size_changed.connect(
		_on_result_container_minimum_size_changed)

	_previous_rect_size = size



func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(quiz: Quiz) -> void:
	_quiz = quiz
	_question.bbcode_enabled = true
	_content.bbcode_enabled = true
	_explanation.bbcode_enabled = true

	if not is_inside_tree():
		await ready

	_question.text = "[b]" + tr(_quiz.question) + "[/b]"

	_content.visible = not _quiz.content_bbcode.is_empty()
	_content.text = TextUtils.bbcode_add_code_color(
		TextUtils.tr_paragraph(_quiz.content_bbcode))

	_explanation.visible = not _quiz.explanation_bbcode.is_empty()
	_explanation.text = TextUtils.bbcode_add_code_color(
		TextUtils.tr_paragraph(_quiz.explanation_bbcode))


func set_completed_before(value: bool) -> void:
	completed_before = value

	if is_inside_tree():
		_completed_before_icon.visible = completed_before


func _update_labels() -> void:
	if not _quiz:
		return

	_question.text = "[b]" + tr(_quiz.question) + "[/b]"

	_content.text = TextUtils.bbcode_add_code_color(
		TextUtils.tr_paragraph(_quiz.content_bbcode))
	_explanation.text = TextUtils.bbcode_add_code_color(
		TextUtils.tr_paragraph(_quiz.explanation_bbcode))


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
		var answers := _get_answers()
		result = _quiz.test_answer(str(answers.back()) if not answers.is_empty() else "")
	_help_message.text = result.help_message
	_help_message.visible = not result.help_message.is_empty()
	if _error_tween:
		_error_tween.kill()
		_error_tween = null

	if not result.is_correct:
		_outline.modulate.a = 1.0
		_outline.add_theme_stylebox_override("panel", ERROR_OUTLINE)

		position.y = _shake_pos

		_error_tween = create_tween()
		_error_tween.set_trans(Tween.TRANS_ELASTIC)
		_error_tween.set_ease(Tween.EASE_OUT)
		_error_tween.tween_property(
			self, "position:y", _shake_pos + ERROR_SHAKE_SIZE, ERROR_SHAKE_TIME)
		_error_tween.tween_property(
			self, "position:y", _shake_pos, ERROR_SHAKE_TIME)

		# Outline flash (delayed fade-out)
		var flash := create_tween()
		flash.tween_property(
			_outline, "modulate:a", 0.0, OUTLINE_FLASH_DURATION
			).set_delay(OUTLINE_FLASH_DELAY)
	else:
		_show_answer()


func _show_answer(gave_correct_answer: bool = true) -> void:
	# Stop previous running tween(s) safely
	if _error_tween:
		_error_tween.kill()
		_error_tween = null
	if _size_tween:
		_size_tween.kill()
		_size_tween = null

	_outline.add_theme_stylebox_override("panel", PASSED_OUTLINE if gave_correct_answer else NEUTRAL_OUTLINE)
	_outline.modulate.a = 1.0

	_result_container.show()

	# Godot 4: use `size` (not rect_size)
	_change_rect_size_to(_result_container.size)

	# Fade out choices, fade in result
	_size_tween = create_tween()

	# choice container alpha 1 -> 0
	_size_tween.tween_property(_choice_container, "modulate:a", 0.0, FADE_OUT_TIME)

	# result container alpha 0 -> 1, delayed by FADE_OUT_TIME
	_size_tween.tween_property(_result_container, "modulate:a", 1.0, FADE_IN_TIME).set_delay(FADE_OUT_TIME)

	if gave_correct_answer:
		emit_signal("quiz_passed")
	else:
		_result_label.text = "The answer was:" if _quiz.get_answer_count() == 1 else "The answers were:"
		_correct_answer_label.show()
		_correct_answer_label.text = _quiz.get_correct_answer_string()
		emit_signal("quiz_skipped")

func _change_rect_size_to(target_size: Vector2, instant: bool = false) -> void:
	if _size_tween:
		_size_tween.kill()
		_size_tween = null

	if instant:
		custom_minimum_size = target_size
		return

	_previous_rect_size = custom_minimum_size
	_next_rect_size = target_size
	_percent_transformed = 0.0

	_size_tween = create_tween()
	_size_tween.set_trans(Tween.TRANS_SINE)
	_size_tween.set_ease(Tween.EASE_IN_OUT)
	_size_tween.tween_property(self, "_percent_transformed", 1.0, SIZE_CHANGE_TIME)

func _on_item_rect_changed() -> void:
	if _error_tween == null:
		_shake_pos = position.y

	if _choice_container.position.x < size.x:
		_choice_container.position.x = size.x
	if _result_container.position.x < size.x:
		_result_container.position.x = size.x

func _on_help_label_visibility_changed() -> void:
	_animating_hint = true

func _on_choice_container_minimum_size_changed() -> void:
	var min_sz: Vector2 = _choice_container.get_combined_minimum_size()
	if _choice_container.size.y > min_sz.y:
		_choice_container.size.y = min_sz.y

	if not _result_container.visible:
		_change_rect_size_to(_choice_container.size, not _animating_hint)
		
func _on_result_container_minimum_size_changed() -> void:
	var min_sz: Vector2 = _result_container.get_combined_minimum_size()
	if _result_container.size.y > min_sz.y:
		_result_container.size.y = min_sz.y

	if _result_container.visible:
		_change_rect_size_to(_result_container.size)
		
func _on_size_tween_step(object: Object, key: NodePath, _elapsed: float, _value: Object) -> void:
	if object == self and key == NodePath(":_percent_transformed") and _next_rect_size != Vector2.ZERO:
		var new_size := _previous_rect_size
		var difference := _next_rect_size - _previous_rect_size
		new_size += difference * _percent_transformed
		custom_minimum_size = new_size

func _on_size_tween_completed(object: Object, key: NodePath) -> void:
	if object == self and key == NodePath(":_percent_transformed"):
		_next_rect_size = Vector2.ZERO
		_animating_hint = false

	# To avoid the buttons being clickable after choice view is gone.
	if object == _choice_container and key == NodePath(":modulate:a"):
		_choice_container.hide()
