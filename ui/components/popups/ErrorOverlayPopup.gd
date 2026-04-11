# Represents an overlay pop-up, which appears when
# hovering a squiggly line.
class_name ErrorOverlayPopup
extends MarginContainer

@export var exclusive := false:
	set = set_exclusive
@export var _error_label: Label
@export var _content_block: Control
@export var _error_explanation_block: Revealer
@export var _error_explanation_value: RichTextLabel
@export var _error_suggestion_block: Revealer
@export var _error_suggestion_value: RichTextLabel
@export var _no_content_label: RichTextLabel
@export var _exclusive_buttons: Control
@export var _close_button: Button

var error_code: int = -1:
	set = set_error_code
var error_message: String:
	set = set_error_message

var _current_message_source: Node
var _error_explanation: String
var _error_suggestion: String


func _ready() -> void:
	_error_label.text = error_message
	_update_explanation()
	_exclusive_buttons.visible = exclusive

	_error_explanation_block.expanded.connect(_on_revealer_opened.bind(_error_explanation_block))
	_error_suggestion_block.expanded.connect(_on_revealer_opened.bind(_error_suggestion_block))
	_close_button.pressed.connect(hide)
	hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_explanation()


func show_message(new_position: Vector2, code: int, message: String, message_source: Node) -> void:
	_current_message_source = message_source

	set_error_code(code)
	set_error_message(message)

	global_position = new_position
	show()


func hide_message(message_source: Node) -> void:
	if _current_message_source == message_source:
		hide()


func set_exclusive(value: bool) -> void:
	exclusive = value

	if is_inside_tree():
		_exclusive_buttons.visible = exclusive


func set_error_code(value: int) -> void:
	error_code = value

	var message_details := GDScriptErrorDatabase.get_message(error_code)
	_error_explanation = message_details.explanation
	_error_suggestion = message_details.suggestion

	_update_explanation()


func set_error_message(value: String) -> void:
	error_message = value

	if is_inside_tree():
		_error_label.text = error_message


func _update_explanation() -> void:
	if not is_inside_tree():
		return

	if _error_explanation.is_empty() and _error_suggestion.is_empty():
		_error_explanation_block.hide()
		_error_suggestion_block.hide()
		_content_block.hide()
		_no_content_label.show()
	else:
		_no_content_label.hide()
		_error_explanation_block.hide()
		_error_suggestion_block.hide()

		if not _error_explanation.is_empty():
			_error_explanation_value.text = TextUtils.tr_paragraph(_error_explanation)
			_error_explanation_block.show()

		if not _error_suggestion.is_empty():
			_error_suggestion_value.text = TextUtils.tr_paragraph(_error_suggestion)
			_error_suggestion_block.show()

		_content_block.show()


func _on_revealer_opened(which: Revealer) -> void:
	if which == _error_explanation_block and _error_suggestion_block.is_expanded:
		_error_suggestion_block.is_expanded = false
	elif which == _error_suggestion_block and _error_explanation_block.is_expanded:
		_error_explanation_block.is_expanded = false
