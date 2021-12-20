tool
extends WindowDialog

signal confirmed

enum ContentType { TEXT, CODE }

var text := "" setget set_text, get_text
var content_type: int = ContentType.TEXT setget set_content_type

onready var _text_value := $Margin/Layout/TextEdit as TextEdit
onready var _confirm_button := $Margin/Layout/Buttons/ConfirmButton as Button
onready var _cancel_button := $Margin/Layout/Buttons/CancelButton as Button


func _ready() -> void:
	_text_value.text = text
	_update_editor_properties()

	_text_value.connect("text_changed", self, "_on_text_changed")
	_confirm_button.connect("pressed", self, "_confirm")
	_cancel_button.connect("pressed", self, "_on_cancel_pressed")

	_text_value.connect("gui_input", self, "_gui_input")


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if event.control and event.pressed and event.scancode == KEY_SPACE:
		_confirm()


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


func popup_centered(size := Vector2.ZERO) -> void:
	.popup_centered(size)
	_text_value.grab_focus()


func set_line_column(line: int, column: int) -> void:
	_text_value.cursor_set_line(line)
	_text_value.cursor_set_column(column)


func get_line() -> int:
	return _text_value.cursor_get_line()


func get_column() -> int:
	return _text_value.cursor_get_column()


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


func _confirm() -> void:
	emit_signal("confirmed")
	hide()


func _on_cancel_pressed() -> void:
	text = ""
	_text_value.text = ""
	emit_signal("canceled")
	hide()
