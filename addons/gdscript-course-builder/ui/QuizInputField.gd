@tool
extends Control

enum TypeOptions { STRING, FLOAT, INT }

var _quiz: QuizInputField

@onready var _correct_answer := $HBoxContainer/LineEdit as LineEdit


func _ready() -> void:
	_correct_answer.text_changed.connect(_on_correct_answer_text_changed)
	# _correct_answer.text_submitted.connect(_on_correct_answer_text_changed) if we want the user to press Enter
func setup(quiz: QuizInputField) -> void:
	_quiz = quiz
	if not is_inside_tree():
		await ready

	_correct_answer.text = str(quiz.valid_answer)

func _on_correct_answer_text_changed(new_text: String) -> void:
	_quiz.valid_answer = new_text
	_quiz.emit_changed()
