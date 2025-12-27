@tool
class_name PracticeHint
extends Revealer

@export_multiline var bbcode_text: String:
	set(value):
		set_bbcode_text(value)

@onready var _rich_text_label := $RichTextLabel as RichTextLabel


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_instance_valid(_rich_text_label):
		_rich_text_label.bbcode_enabled = true
		_rich_text_label.text = TextUtils.tr_paragraph(bbcode_text)


func set_bbcode_text(new_text: String) -> void:
	bbcode_text = new_text
	if not is_inside_tree():
		await ready
	_rich_text_label.bbcode_enabled = true
	_rich_text_label.text = TextUtils.tr_paragraph(bbcode_text)
