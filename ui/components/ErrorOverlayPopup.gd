# Represents an overlay pop-up, which appears when
# hovering a squiggly line.
class_name ErrorOverlayPopup
extends MarginContainer

var error_code: int = -1 setget set_error_code
var error_message: String setget set_error_message

var _current_message_source: Node
var _error_explanation: String
var _error_suggestion: String

onready var _error_label := $MarginContainer/Column/ErrorLabel as Label
onready var _error_explanation_value := ( $MarginContainer/Column/ErrorExplanation/Value as RichTextLabel)
onready var _more_help_button := $MarginContainer/Column/ErrorExplanation/MoreHelpButton as Button
onready var _error_suggestion_value := ($MarginContainer/Column/ErrorSuggestion/Value as RichTextLabel)


func _ready() -> void:
	_error_label.text = error_message
	_error_explanation_value.text = _error_explanation
	_error_suggestion_value.text = _error_suggestion

	hide()


func show_message(position: Vector2, code: int, message: String, message_source: Node) -> void:
	_current_message_source = message_source

	set_error_code(code)
	set_error_message(message)

	rect_global_position = position
	show()


func hide_message(message_source: Node) -> void:
	if _current_message_source == message_source:
		hide()


func set_error_code(value: int) -> void:
	error_code = value

	var message_details := LiveEditorState.error_database.get_message(error_code)
	_error_explanation = message_details.explanation
	_error_suggestion = message_details.suggestion

	if is_inside_tree():
		_error_explanation_value.bbcode_text = _error_explanation
		_error_suggestion_value.bbcode_text = _error_suggestion


func set_error_message(value: String) -> void:
	error_message = value

	if is_inside_tree():
		_error_label.text = error_message
