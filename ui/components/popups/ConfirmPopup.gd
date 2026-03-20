@tool
class_name ConfirmPopup
extends ColorRect

signal confirmed

const STRICT_COLOR := Color(1, 0.094118, 0.321569)
const NORMAL_COLOR := Color(0.239216, 1, 0.431373)
const STRICT_STYLEBOX := preload("res://ui/theme/button_outline_large_strict.tres")
const NORMAL_STYLEBOX := preload("res://ui/theme/button_outline_large_accent.tres")
const STRICT_FOCUS_STYLEBOX := preload("res://ui/theme/focus_strict.tres")
const NORMAL_FOCUS_STYLEBOX := preload("res://ui/theme/focus_accent.tres")

@export var title := "": set = set_title
@export var text_content := "": set = set_text_content
@export var min_size := Vector2(200, 120): set = set_min_size
@export var strict := false: set = set_strict

@onready var _root_container := $PanelContainer as Container
@onready var _top_bar := $PanelContainer/Column/ProgressBar as ProgressBar
@onready var _title_label := $PanelContainer/Column/Margin/Column/Title as Label
@onready var _message_content := $PanelContainer/Column/Margin/Column/Message as RichTextLabel

@onready var _confirm_button := $PanelContainer/Column/Margin/Column/Buttons/ConfirmButton as Button
@onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _ready():
	set_as_top_level(true)
	_root_container.custom_minimum_size = min_size
	_root_container.size = _root_container.custom_minimum_size
	_root_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	_title_label.text = tr(title)
	_message_content.text = tr(text_content)
	_update_top_bar()
	
	_confirm_button.connect("pressed", Callable(self, "emit_signal").bind("confirmed"))
	_cancel_button.connect("pressed", Callable(self, "hide"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_title_label):
			_title_label.text = tr(title)
		if is_instance_valid(_message_content):
			_message_content.text = tr(text_content)


func set_title(value: String) -> void:
	title = value
	if is_inside_tree():
		_title_label.text = tr(title)


func set_text_content(value: String) -> void:
	text_content = value
	if is_inside_tree():
		_message_content.text = tr(text_content)


func set_min_size(value: Vector2) -> void:
	min_size = value
	if is_inside_tree():
		_root_container.custom_minimum_size = min_size
		_root_container.size = _root_container.custom_minimum_size
		_root_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)


func set_strict(value: bool) -> void:
	strict = value
	_update_top_bar()


func popup() -> void:
	show()
	_root_container.size = _root_container.custom_minimum_size
	_root_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_cancel_button.grab_focus()


func _update_top_bar() -> void:
	if not is_inside_tree():
		return
	
	var highlight_color := NORMAL_COLOR
	var button_stylebox := NORMAL_STYLEBOX
	var button_focus_stylebox := NORMAL_FOCUS_STYLEBOX
	if strict:
		highlight_color = STRICT_COLOR
		button_stylebox = STRICT_STYLEBOX
		button_focus_stylebox = STRICT_FOCUS_STYLEBOX
	
	var bar_style := _top_bar.get_theme_stylebox("fg").duplicate()
	if bar_style is StyleBoxFlat:
		(bar_style as StyleBoxFlat).bg_color = highlight_color
	_top_bar.add_theme_stylebox_override("fg", bar_style)
	
	_confirm_button.add_theme_stylebox_override("focus", button_focus_stylebox)
	_confirm_button.add_theme_stylebox_override("hover", button_stylebox)
	_confirm_button.add_theme_stylebox_override("pressed", button_stylebox)
	_confirm_button.add_theme_color_override("font_color_hover", highlight_color)
	_confirm_button.add_theme_color_override("font_color_pressed", highlight_color)
