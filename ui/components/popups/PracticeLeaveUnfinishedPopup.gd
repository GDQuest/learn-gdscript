@tool
extends ColorRect

signal confirmed
signal denied

@onready var _root_container: Container = %PanelContainer
@onready var _center_container: CenterContainer = %CenterContainer
@onready var _title_label: Label = %Title
@onready var _message_content: RichTextLabel = %Message
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton

@export var title := "":
	set = set_title
@export var text_content := "":
	set = set_text_content
@export var min_size := Vector2(200, 120):
	set = set_min_size


func _ready():
	_root_container.custom_minimum_size = min_size

	_title_label.text = tr(title)
	_message_content.text = tr(text_content)

	_confirm_button.pressed.connect(confirmed.emit)
	_confirm_button.pressed.connect(hide)

	_cancel_button.pressed.connect(denied.emit)
	_cancel_button.pressed.connect(hide)

	if not Engine.is_editor_hint():
		set_as_top_level(true)
		# visibility_changed.connect(
		# 	func _on_visibility_changed() -> void:
		# 		_center_container.visible = visible,
		# )
		hide.call_deferred()


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


func popup() -> void:
	show()
	_cancel_button.grab_focus()
