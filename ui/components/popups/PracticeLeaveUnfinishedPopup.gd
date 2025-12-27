@tool
extends ColorRect

signal confirmed
signal denied

@export var title: String:
	set(value):
		set_title(value)

@export_multiline var text_content: String:
	set(value):
		set_text_content(value)

@export var min_size: Vector2 = Vector2(200, 120):
	set(value):
		set_min_size(value)


@onready var _root_container := $PanelContainer as Container
@onready var _top_bar := $PanelContainer/Column/ProgressBar as ProgressBar
@onready var _title_label := $PanelContainer/Column/Margin/Column/Title as Label
@onready var _message_content := $PanelContainer/Column/Margin/Column/Message as RichTextLabel

@onready var _confirm_button := $PanelContainer/Column/Margin/Column/Buttons/ConfirmButton as Button
@onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _ready():
	top_level = true
	_root_container.rect_min_size = min_size
	_root_container.rect_size = _root_container.rect_min_size
	_root_container.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	
	_title_label.text = tr(title)
	_message_content.bbcode_text = tr(text_content)
	
	_confirm_button.pressed.connect(confirmed.emit)
	_confirm_button.pressed.connect(hide)

	_cancel_button.pressed.connect(denied.emit)
	_cancel_button.pressed.connect(hide)



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
