tool
extends Control

enum TypeOptions { STRING, FLOAT, INT }

var _quizz: QuizzInputField

onready var _correct_answer := $HBoxContainer/LineEdit as LineEdit


func _ready() -> void:
	_correct_answer.connect("text_changed", self, "_on_correct_answer_text_changed")


func setup(quizz: QuizzInputField) -> void:
	_quizz = quizz
	if not is_inside_tree():
		yield(self, "ready")

	_correct_answer.text = str(quizz.valid_answer)


func _on_correct_answer_text_changed(new_text: String) -> void:
	_quizz.valid_answer = new_text
	_quizz.emit_changed()
