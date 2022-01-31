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
const FADE_OUT_TIME := 0.15
const FADE_IN_TIME := 0.15
const INTERPOLATION_TIME := 0.3

export var test_quiz: Resource

var completed_before := false setget set_completed_before

onready var _outline := $Outline as PanelContainer
onready var _question := $MarginContainer/BoundaryControl/ChoiceView/QuizHeader/Question as RichTextLabel
onready var _explanation := $MarginContainer/BoundaryControl/ResultView/Explanation as RichTextLabel
onready var _content := $MarginContainer/BoundaryControl/ChoiceView/Content as RichTextLabel
onready var _completed_before_icon := (
	$MarginContainer/BoundaryControl/ChoiceView/QuizHeader/CompletedBeforeIcon as TextureRect
)

onready var _margin_container := $MarginContainer as MarginContainer
onready var _boundary_control := $MarginContainer/BoundaryControl as Control
onready var _choice_view := $MarginContainer/BoundaryControl/ChoiceView as VBoxContainer
onready var _result_view := $MarginContainer/BoundaryControl/ResultView as VBoxContainer

onready var _submit_button := $MarginContainer/BoundaryControl/ChoiceView/HBoxContainer/SubmitButton as Button
onready var _skip_button := $MarginContainer/BoundaryControl/ChoiceView/HBoxContainer/SkipButton as Button

onready var _result_label := $MarginContainer/BoundaryControl/ResultView/Label as Label
onready var _correct_answer_label := $MarginContainer/BoundaryControl/ResultView/CorrectAnswer as Label

onready var _tween := $Tween as Tween
onready var _help_message := $MarginContainer/BoundaryControl/ChoiceView/HelpMessage as Label

var _quiz: Quiz
var _shake_pos: float = 0
# For animating changing the size of the container
var _current_rect_size := rect_size
var _next_rect_size := Vector2.ZERO
var _percent_transformed: float = 0


func _ready() -> void:
	_completed_before_icon.visible = completed_before

	_submit_button.connect("pressed", self, "_test_answer")
	_skip_button.connect("pressed", self, "_show_answer", [false])
	connect("item_rect_changed", self, "_on_item_rect_changed")
	
	_choice_view.connect("minimum_size_changed", self, "_on_choice_view_minimum_size_changed")
	
	_tween.connect("tween_step", self, "_on_tween_step")
	_tween.connect("tween_completed", self, "_on_tween_completed")


func setup(quiz: Quiz) -> void:
	_quiz = quiz

	if not is_inside_tree():
		yield(self, "ready")

	_question.bbcode_text = "[b]" + quiz.question + "[/b]"

	_content.visible = not _quiz.content_bbcode.empty()
	_content.bbcode_text = TextUtils.bbcode_add_code_color(_quiz.content_bbcode)

	_explanation.visible = not _quiz.explanation_bbcode.empty()
	_explanation.bbcode_text = TextUtils.bbcode_add_code_color(_quiz.explanation_bbcode)
	
	rect_min_size = _get_min_size_needed(_choice_view)


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

		rect_position.y = _shake_pos
		_tween.interpolate_property(
			self,
			"rect_position:y",
			_shake_pos + ERROR_SHAKE_SIZE,
			_shake_pos,
			ERROR_SHAKE_TIME,
			Tween.TRANS_ELASTIC,
			Tween.EASE_OUT
		)
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

func _get_min_size_needed(view: Control) -> Vector2:
	# Adds the minimum size from the view and adds the margins from margincontainer
	# and a little more for visual integrity (Buttons clip bottom of boundary without)
	return view.get_combined_minimum_size() + rect_size - _boundary_control.rect_size + Vector2(0, 10)

func _show_answer(gave_correct_answer := true) -> void:
	_tween.stop_all()
	_outline.add_stylebox_override("panel", PASSED_OUTLINE if gave_correct_answer else NEUTRAL_OUTLINE)
	_outline.modulate.a = 1.0
	
	
	_result_view.show()
	
	_change_rect_size(_get_min_size_needed(_result_view))
	
	_tween.interpolate_property(
		_choice_view,
		"modulate:a",
		_choice_view.modulate.a,
		0,
		FADE_OUT_TIME
	)
	
	_tween.interpolate_property(
		_result_view,
		"modulate:a",
		0,
		1,
		FADE_IN_TIME,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN,
		FADE_OUT_TIME
	)
	
	_tween.start()
	
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

func _change_rect_size(target: Vector2) -> void:
	_tween.stop_all()
	
	_current_rect_size = rect_min_size
	_next_rect_size = target
	_percent_transformed = 0
	
	_tween.interpolate_property(
		self, 
		"_percent_transformed", 
		0.0, 
		1.0,
		INTERPOLATION_TIME,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	
	_tween.start()

func _on_choice_view_minimum_size_changed() -> void:
	_change_rect_size(_get_min_size_needed(_choice_view))


func _on_item_rect_changed() -> void:
	if not _tween.is_active() or _tween.tell() > ERROR_SHAKE_TIME:
		_shake_pos = rect_position.y

func _on_tween_step(object: Object, _key: NodePath, _elapsed: float, _value: Object) -> void:
	if object == self and _next_rect_size != Vector2.ZERO:
		var final_size := _current_rect_size
		var difference := _next_rect_size - _current_rect_size
		final_size += difference * _percent_transformed
		rect_min_size = final_size

func _on_tween_completed(_object: Object, key: NodePath) -> void:
	if key == "_percent_transformed":
		_current_rect_size = _next_rect_size
		_next_rect_size = Vector2.ZERO
		_percent_transformed = 0
