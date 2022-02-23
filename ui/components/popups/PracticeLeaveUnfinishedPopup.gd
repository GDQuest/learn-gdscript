tool
extends ColorRect

signal confirmed
signal denied

export var title := "" setget set_title
export(String, MULTILINE) var text_content := "" setget set_text_content
export var min_size := Vector2(200, 120) setget set_min_size

onready var _root_container := $PanelContainer as Container
onready var _top_bar := $PanelContainer/Column/ProgressBar as ProgressBar
onready var _title_label := $PanelContainer/Column/Margin/Column/Title as Label
onready var _message_content := $PanelContainer/Column/Margin/Column/Message as RichTextLabel

onready var _confirm_button := $PanelContainer/Column/Margin/Column/Buttons/ConfirmButton as Button
onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _ready():
	set_as_toplevel(true)
	_root_container.rect_min_size = min_size
	_root_container.rect_size = _root_container.rect_min_size
	_root_container.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	
	_title_label.text = tr(title)
	_message_content.bbcode_text = tr(text_content)
	
	_confirm_button.connect("pressed", self, "emit_signal", ["confirmed"])
	_confirm_button.connect("pressed", self, "hide")

	_cancel_button.connect("pressed", self, "emit_signal", ["denied"])
	_cancel_button.connect("pressed", self, "hide")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_title_label):
			_title_label.text = tr(title)
		if is_instance_valid(_message_content):
			_message_content.bbcode_text = tr(text_content)


func set_title(value: String) -> void:
	title = value
	if is_inside_tree():
		_title_label.text = tr(title)


func set_text_content(value: String) -> void:
	text_content = value
	if is_inside_tree():
		_message_content.bbcode_text = tr(text_content)


func set_min_size(value: Vector2) -> void:
	min_size = value
	if is_inside_tree():
		_root_container.rect_min_size = min_size
		_root_container.rect_size = _root_container.rect_min_size
		_root_container.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)


func popup() -> void:
	show()
	_root_container.rect_size = _root_container.rect_min_size
	_root_container.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_cancel_button.grab_focus()
