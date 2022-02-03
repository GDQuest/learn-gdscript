class_name UIQuizInputField
extends UIBaseQuiz

onready var _line_edit := $ClipContentBoundary/ChoiceContainer/ChoiceView/Answers/LineEdit as LineEdit


func _ready() -> void:
	_line_edit.connect("text_entered", self, "_test_answer")


func _get_answers() -> Array:
	return [_line_edit.text]
