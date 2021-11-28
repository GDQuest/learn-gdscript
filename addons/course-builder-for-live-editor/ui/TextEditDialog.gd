tool
extends WindowDialog

signal confirmed

enum ContentType {TEXT, CODE}

var text := "" setget set_text, get_text
var content_type: int = ContentType.TEXT setget set_content_type

onready var _text_value := $Margin/Layout/TextEdit as TextEdit
onready var _confirm_button := $Margin/Layout/Buttons/ConfirmButton as Button
onready var _cancel_button := $Margin/Layout/Buttons/CancelButton as Button


func _ready() -> void:
	_text_value.text = text
	_update_editor_properties()

	_text_value.connect("text_changed", self, "_on_text_changed")
	_confirm_button.connect("pressed", self, "_on_confirm_pressed")
	_cancel_button.connect("pressed", self, "_on_cancel_pressed")


# Properties
func set_text(value: String) -> void:
	text = value

	if is_inside_tree():
		_text_value.text = text


func get_text() -> String:
	if is_inside_tree():
		return _text_value.text

	return text


func set_content_type(value: int) -> void:
	content_type = value
	_update_editor_properties()


# Helpers
func _update_editor_properties() -> void:
	if not is_inside_tree():
		return

	if content_type == ContentType.CODE:
		_text_value.show_line_numbers = true
		_text_value.draw_tabs = true
		_text_value.draw_spaces = true
		_text_value.add_font_override("font", get_font("source", "EditorFonts"))
	else:
		_text_value.show_line_numbers = false
		_text_value.draw_tabs = false
		_text_value.draw_spaces = false
		_text_value.add_font_override("font", get_font("font", "TextEdit"))


# Handlers
func _on_text_changed() -> void:
	text = _text_value.text


func _on_confirm_pressed() -> void:
	emit_signal("confirmed")
	hide()


func _on_cancel_pressed() -> void:
	text = ""
	_text_value.text = ""
	hide()
