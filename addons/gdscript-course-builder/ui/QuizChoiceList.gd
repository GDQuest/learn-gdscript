tool
extends VBoxContainer

const QuizChoiceScene = preload("QuizChoiceItem.tscn")

var _quiz: QuizChoice
var _answers := []
var _button_group := ButtonGroup.new()

onready var _add_button := $Header/AddButton as Button


func _ready() -> void:
	_add_button.connect("pressed", self, "_add_answer")


func setup(quiz: QuizChoice) -> void:
	_quiz = quiz
	if not is_inside_tree():
		yield(self, "ready")
	_quiz.connect("choice_type_changed", self, "_update_children_checkboxes")

	for answer in quiz.answer_options:
		_add_answer(answer)


func _update_answer_labels() -> void:
	var index := 1
	for child in get_children():
		if child is QuizChoiceItem:
			child.set_list_index(index)
			index += 1


func _update_quiz_answers() -> void:
	_quiz.answer_options.clear()
	_quiz.valid_answers.clear()
	for child in get_children():
		if not child is QuizChoiceItem or child.is_queued_for_deletion():
			continue

		_quiz.answer_options.append(child.get_answer_text())
		if child.is_valid_answer():
			_quiz.valid_answers.append(child.get_answer_text())
	_quiz.emit_changed()


func _add_answer(answer := "") -> void:
	var instance = QuizChoiceScene.instance()
	add_child(instance)
	instance.button_group = _button_group
	instance.is_radio = not _quiz.is_multiple_choice
	instance.set_answer_text(answer)
	instance.set_valid_answer(answer in _quiz.valid_answers)
	instance.connect("index_changed", self, "_update_answer_labels")
	instance.connect("choice_changed", self, "_update_quiz_answers")
	instance.connect("removed", self, "_update_quiz_answers")


func _update_children_checkboxes(is_multiple_choice: bool) -> void:
	for child in get_children():
		if not child is QuizChoiceItem or child.is_queued_for_deletion():
			continue

		child.is_radio = not is_multiple_choice
