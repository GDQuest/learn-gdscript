@tool
class_name PracticeHint
extends Revealer

@export var text: String:
	set = set_bbcode_text

@export var _rich_text_label: RichTextLabel


func _ready() -> void:
	super()

	_update_rtl_text()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_rtl_text()


func set_bbcode_text(new_text: String) -> void:
	text = new_text
	_update_rtl_text()


func _update_rtl_text() -> void:
	if not is_node_ready():
		return

	if Engine.is_editor_hint():
		_rich_text_label.text = text
	else:
		_rich_text_label.text = TextUtils.tr_paragraph(text)
