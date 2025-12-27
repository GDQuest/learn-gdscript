@tool
extends Window

signal confirmed

var _slug_text: String = ""

var slug_text: String:
	set(value):
		set_text(value)
	get:
		return get_text()


@onready var _slug_label := $Margin/Layout/SlugText/Label as Label
@onready var _slug_value := $Margin/Layout/SlugText/LineEdit as LineEdit
@onready var _confirm_button := $Margin/Layout/Buttons/ConfirmButton as Button
@onready var _cancel_button := $Margin/Layout/Buttons/CancelButton as Button


func _ready() -> void:
	_update_theme()
	_slug_value.text = _slug_text

	_slug_value.text_changed.connect(_on_text_changed)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)


func _update_theme() -> void:
	if not is_inside_tree():
		return

	_slug_label.add_theme_color_override(
	"font_color",
	get_theme_color("disabled_font_color", "Editor")
	)

# Properties
func set_text(value: String) -> void:
	_slug_text = value
	if is_inside_tree():
		_slug_value.text = _slug_text



func get_text() -> String:
	if is_inside_tree():
		return _slug_value.text
	return _slug_text

# Handlers
func _on_text_changed(value: String) -> void:
	_slug_text = value


func _on_confirm_pressed() -> void:
	confirmed.emit()
	hide()


func _on_cancel_pressed() -> void:
	_slug_text = ""
	_slug_value.text = ""
	hide()
