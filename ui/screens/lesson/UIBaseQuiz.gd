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

var completed_before := false: set = set_completed_before

@export var _outline: PanelContainer
@export var _question: RichTextLabel
@export var _explanation: RichTextLabel
@export var _content: RichTextLabel
@export var _completed_before_icon: TextureRect
@export var _choice_container: MarginContainer
@export var _result_container: MarginContainer
@export var _submit_button: Button
@export var _skip_button: Button
@export var _result_label: Label
@export var _correct_answer_label: Label
@export var _help_message: Label

var _quiz: BBCodeParser.ParseNode
var _quiz_data: BBCodeUtils.QuizData
var _shake_pos: float = 0
# Used for animating size changes
var _previous_rect_size := size
var _next_rect_size := Vector2.ZERO
var _percent_transformed := 0.0
var _animating_hint := false

var _error_scene_tween: Tween
var _size_scene_tween: Tween

func _ready() -> void:
	_completed_before_icon.visible = completed_before

	_submit_button.pressed.connect(_test_answer)
	_skip_button.pressed.connect(_show_answer.bind(false))
	item_rect_changed.connect(_on_item_rect_changed)

	_help_message.visibility_changed.connect(_on_help_label_visibility_changed)
	_choice_container.minimum_size_changed.connect(_on_choice_container_minimum_size_changed)
	_result_container.minimum_size_changed.connect(_on_result_container_minimum_size_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(quiz: BBCodeParser.ParseNode) -> void:
	_quiz = quiz
	_quiz_data = BBCodeUtils.get_quiz_data(_quiz)

	if not is_inside_tree():
		await self.ready

	var question: String = _quiz_data.question
	_question.text = "[b]" + tr(question) + "[/b]"

	var content: String = _quiz_data.content
	_content.visible = not content.is_empty()
	_content.text = TextUtils.bbcode_add_code_color(TextUtils.tr_paragraph(content))

	var explanation: String = _quiz_data.explanation
	_explanation.visible = not explanation.is_empty()
	_explanation.text = TextUtils.bbcode_add_code_color(TextUtils.tr_paragraph(explanation))


func set_completed_before(value: bool) -> void:
	completed_before = value

	if is_inside_tree():
		_completed_before_icon.visible = completed_before


func _update_labels() -> void:
	if not _quiz:
		return

	var question := _quiz_data.question
	_question.text = "[b]" + tr(question) + "[/b]"

	var content_bbcode := _quiz_data.content
	_content.text = TextUtils.bbcode_add_code_color(TextUtils.tr_paragraph(content_bbcode))
	var explanation_bbcode := _quiz_data.explanation
	_explanation.text = TextUtils.bbcode_add_code_color(TextUtils.tr_paragraph(explanation_bbcode))


# Virtual
func _get_answers() -> Array:
	return []


func _test_answer() -> void:
	var result: AnswerTestResult = null
	_skip_button.disabled = false
	if _quiz.tag == BBCodeParserData.Tag.QUIZ_CHOICE:
		result = _test_answer_against_quiz(_get_answers())
	else:
		# The input field quiz takes a single string as a test answer.
		result = _test_answer_against_quiz(_get_answers().back())
	_help_message.text = result.help_message
	_help_message.visible = not result.help_message.is_empty()
	
	if not result.is_correct:
		_outline.modulate.a = 1.0
		_outline.add_theme_stylebox_override("panel", ERROR_OUTLINE)

		position.y = _shake_pos
		
		if _error_scene_tween:
			_error_scene_tween.kill()
		_error_scene_tween = create_tween().set_parallel()
		_error_scene_tween.tween_property(self, "position:y", _shake_pos, ERROR_SHAKE_TIME).from(_shake_pos + ERROR_SHAKE_SIZE).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_error_scene_tween.tween_property(_outline, "modulate:a", 0.0, OUTLINE_FLASH_DURATION).from(_outline.modulate.a).set_ease(Tween.EASE_IN)
	else:
		_show_answer()


func _test_answer_against_quiz(answers: Array) -> AnswerTestResult:
	return null


func _show_answer(gave_correct_answer := true) -> void:
	if _error_scene_tween:
		_error_scene_tween.kill()
	_outline.add_theme_stylebox_override("panel", PASSED_OUTLINE if gave_correct_answer else NEUTRAL_OUTLINE)
	_outline.modulate.a = 1.0


	_result_container.show()
	_change_rect_size_to(_result_container.size)

	#Hiding choice view upon completion of the following tween
	var fade_tween := create_tween().set_parallel()
	
	var choice_step := fade_tween.tween_property(_choice_container, "modulate:a", 0.0, FADE_OUT_TIME).from(1.0)
	choice_step.finished.connect(_choice_container.hide)
	fade_tween.tween_property(_result_container, "modulate:a", 1.0, FADE_IN_TIME).from(0.0)

	if gave_correct_answer:
		emit_signal("quiz_passed")
	else:
		if _quiz_data.get_answer_count() == 1:
			_result_label.text = "The answer was:"
		else:
			_result_label.text = "The answers were:"
		_correct_answer_label.show()
		_correct_answer_label.text = _quiz_data.get_correct_answer_string()
		emit_signal("quiz_skipped")


func _change_rect_size_to(size: Vector2, instant := false) -> void:

	if instant:
		custom_minimum_size = size
		return

	_previous_rect_size = custom_minimum_size
	_next_rect_size = size
	_percent_transformed = 0.0

	if _size_scene_tween:
		_size_scene_tween.kill()
	_size_scene_tween = create_tween().set_parallel()
	_size_scene_tween.tween_property(self, "_percent_transformed", 1.0, SIZE_CHANGE_TIME).from(0.0).set_trans(Tween.TRANS_SINE)
	_size_scene_tween.tween_method(Callable(self, "_on_size_tween_step"), 0.0, 1.0, SIZE_CHANGE_TIME).set_trans(Tween.TRANS_SINE)
	_size_scene_tween.finished.connect(_on_size_tween_completed)

func _on_item_rect_changed() -> void:
	if not _error_scene_tween or not _error_scene_tween.is_running() or _error_scene_tween.get_total_elapsed_time() > ERROR_SHAKE_TIME:
		_shake_pos = position.y

	if _choice_container.size.x < size.x:
		_choice_container.size.x = size.x
	if _result_container.size.x < size.x:
		_result_container.size.x = size.x

func _on_help_label_visibility_changed() -> void:
	_animating_hint = true

func _on_choice_container_minimum_size_changed() -> void:
	if _choice_container.size.y > _choice_container.get_combined_minimum_size().y:
		_choice_container.size.y = _choice_container.get_combined_minimum_size().y

	if not _result_container.visible:
		# If not animating the hint, just resize normally.
		_change_rect_size_to(_choice_container.size, !_animating_hint)

func _on_result_container_minimum_size_changed() -> void:
	if _result_container.size.y > _result_container.get_combined_minimum_size().y:
		_result_container.size.y = _result_container.get_combined_minimum_size().y

	if _result_container.visible:
		_change_rect_size_to(_result_container.size)


func _on_size_tween_step(value: float) -> void:
	if _next_rect_size != Vector2.ZERO:
		var new_size := _previous_rect_size
		var difference := _next_rect_size - _previous_rect_size
		new_size += difference * value
		custom_minimum_size = new_size


func _on_size_tween_completed() -> void:
	_next_rect_size = Vector2.ZERO
	_animating_hint = false



class AnswerTestResult:
	var is_correct := false
	var help_message := ""
