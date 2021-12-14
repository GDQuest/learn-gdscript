tool
extends VBoxContainer

const QuizzChoiceScene = preload("QuizzChoiceItem.tscn")

var _quizz: QuizzChoice
var _answers := []
var _button_group := ButtonGroup.new()

onready var _add_button := $Header/AddButton as Button


func _ready() -> void:
	_add_button.connect("pressed", self, "_add_answer")


func setup(quizz: QuizzChoice) -> void:
	_quizz = quizz
	if not is_inside_tree():
		yield(self, "ready")
	_quizz.connect("choice_type_changed", self, "_update_children_checkboxes")

	for answer in quizz.answer_options:
		_add_answer(answer)


func _update_answer_labels() -> void:
	var index := 1
	for child in get_children():
		if child is QuizzChoiceItem:
			child.set_list_index(index)
			index += 1


func _update_quizz_answers() -> void:
	_quizz.answer_options.clear()
	_quizz.valid_answers.clear()
	for child in get_children():
		if not child is QuizzChoiceItem or child.is_queued_for_deletion():
			continue

		_quizz.answer_options.append(child.get_answer_text())
		if child.is_valid_answer():
			_quizz.valid_answers.append(child.get_answer_text())
	_quizz.emit_changed()


func _add_answer(answer := "") -> void:
	var instance = QuizzChoiceScene.instance()
	add_child(instance)
	instance.is_radio = not _quizz.is_multiple_choice
	instance.button_group = _button_group
	instance.set_answer_text(answer)
	instance.set_valid_answer(answer in _quizz.valid_answers)
	instance.connect("index_changed", self, "_update_answer_labels")
	instance.connect("choice_changed", self, "_update_quizz_answers")
	instance.connect("removed", self, "_update_quizz_answers")


func _update_children_checkboxes(is_multiple_choice: bool) -> void:
	for child in get_children():
		if not child is QuizzChoiceItem or child.is_queued_for_deletion():
			continue

		child.is_radio = not is_multiple_choice
