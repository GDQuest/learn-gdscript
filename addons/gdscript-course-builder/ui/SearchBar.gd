tool
extends HBoxContainer

signal next_match_requested(text)

var is_active: bool setget set_is_active
var search_text: String setget set_search_text

onready var _line_edit := $LineEdit as LineEdit
onready var _next_button := $NextButton as Button


func _ready() -> void:
	set_is_active(false)
	_line_edit.connect("text_entered", self, "set_search_text")
	_next_button.connect("pressed", self, "_request_next_match")


func set_search_text(text: String) -> void:
	if text == search_text:
		return
	search_text = text
	if not search_text.empty():
		emit_signal("next_match_requested", search_text)


func set_is_active(value: bool) -> void:
	is_active = value
	if not is_inside_tree():
		yield(self, "ready")
	_line_edit.editable = is_active
	_next_button.disabled = not is_active


func _request_next_match() -> void:
	if search_text.empty():
		search_text = _line_edit.text
	if not search_text.empty():
		emit_signal("next_match_requested", search_text)
