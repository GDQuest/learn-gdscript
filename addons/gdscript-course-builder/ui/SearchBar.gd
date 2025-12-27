@tool
extends HBoxContainer

signal next_match_requested(text: String)


var _is_active: bool = false
var _search_text: String = ""

var is_active: bool:
	set(value):
		set_is_active(value)
	get:
		return _is_active

var search_text: String:
	set(value):
		set_search_text(value)
	get:
		return _search_text


@onready var _line_edit := $LineEdit as LineEdit
@onready var _next_button := $NextButton as Button


func _ready() -> void:
	set_is_active(false)
	_line_edit.text_submitted.connect(set_search_text)
	_next_button.pressed.connect(_request_next_match)



func set_search_text(text: String) -> void:
	if text == _search_text:
		return

	_search_text = text
	if not _search_text.is_empty():
		next_match_requested.emit(_search_text)



func set_is_active(value: bool) -> void:
	_is_active = value
	if not is_inside_tree():
		await ready
	_line_edit.editable = _is_active
	_next_button.disabled = not _is_active


func _request_next_match() -> void:
	if _search_text.is_empty():
		_search_text = _line_edit.text
	if not _search_text.is_empty():
		next_match_requested.emit(_search_text)
