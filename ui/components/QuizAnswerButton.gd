extends PanelContainer

signal toggled(is_pressed)

const OPTION_FONT := preload("res://ui/theme/fonts/font_text.tres")
const OPTION_SELECTED_FONT := preload("res://ui/theme/fonts/font_text_bold.tres")

var _button = null

onready var _margin_container := $MarginContainer as MarginContainer
onready var _label := $MarginContainer/Label as Label
onready var _group: ButtonGroup = preload("QuizAnswerButtonGroup.tres")


func setup(text: String, is_multiple_choice: bool) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_label.text = text
	_label.add_font_override("font", OPTION_FONT)
	_button =  CheckBox.new()
	_button.toggle_mode = true
	_button.connect("toggled", self, "_on_toggled")
	if not is_multiple_choice:
		_button.group = _group
	add_child(_button)
	_margin_container.raise()


func get_answer() -> String:
	return _label.text if _button.pressed else ""


func _on_toggled(is_pressed: bool) -> void:
	_label.add_font_override("font", OPTION_SELECTED_FONT if is_pressed else OPTION_FONT)
