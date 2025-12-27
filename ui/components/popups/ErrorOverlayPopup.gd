# Represents an overlay pop-up, which appears when
# hovering a squiggly line.
class_name ErrorOverlayPopup
extends MarginContainer

@export var exclusive: bool = false:
	set(value):
		set_exclusive(value)

var error_code: int = -1:
	set(value):
		set_error_code(value)

var error_message: String = "":
	set(value):
		set_error_message(value)

var _current_message_source: Node
var _error_explanation: String = ""
var _error_suggestion: String = ""

@onready var _error_label: Label = $MarginContainer/Column/ErrorLabel
@onready var _content_block: Control = $MarginContainer/Column/Content

# NOTE: We intentionally type these as Control (not Revealer) because Revealer.gd
# may not parse yet during migration. We still connect to the "expanded" signal
# and read/write "is_expanded" dynamically.
@onready var _error_explanation_block: Control = $MarginContainer/Column/Content/ErrorExplanation
@onready var _error_explanation_value: RichTextLabel = $MarginContainer/Column/Content/ErrorExplanation/Value

@onready var _error_suggestion_block: Control = $MarginContainer/Column/Content/ErrorSuggestion
@onready var _error_suggestion_value: RichTextLabel = $MarginContainer/Column/Content/ErrorSuggestion/Value

@onready var _no_content_label: RichTextLabel = $MarginContainer/Column/NoContent

@onready var _exclusive_buttons: Control = $MarginContainer/Column/Buttons
@onready var _close_button: Button = $MarginContainer/Column/Buttons/CloseButton


func _ready() -> void:
	_error_label.text = error_message
	_update_explanation()
	_exclusive_buttons.visible = exclusive

	# Godot 4 connect style (string signal + Callable). Works even if Revealer.gd doesn't parse yet.
	_error_explanation_block.connect(
		"expanded",
		Callable(self, "_on_revealer_opened").bind(_error_explanation_block)
	)
	_error_suggestion_block.connect(
		"expanded",
		Callable(self, "_on_revealer_opened").bind(_error_suggestion_block)
	)

	_close_button.pressed.connect(hide)
	hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_explanation()


func show_message(pos: Vector2, code: int, message: String, message_source: Node) -> void:
	_current_message_source = message_source

	set_error_code(code)
	set_error_message(message)

	# Godot 4: rect_global_position -> global_position
	global_position = pos
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
		return

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


func _on_revealer_opened(which: Control) -> void:
	var sug_val = _error_suggestion_block.get("is_expanded")
	var exp_val = _error_explanation_block.get("is_expanded")

	var sug_expanded: bool = sug_val is bool and sug_val
	var exp_expanded: bool = exp_val is bool and exp_val

	if which == _error_explanation_block and sug_expanded:
		_error_suggestion_block.set("is_expanded", false)
	elif which == _error_suggestion_block and exp_expanded:
		_error_explanation_block.set("is_expanded", false)
