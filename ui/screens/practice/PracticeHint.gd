@tool
class_name PracticeHint
extends Revealer

@export var text: String: set = set_bbcode_text

@onready var _rich_text_label := $RichTextLabel as RichTextLabel


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_rich_text_label):
			_rich_text_label.text = TextUtils.tr_paragraph(text)


func set_bbcode_text(new_text: String) -> void:
	text = new_text
	if not is_inside_tree():
		await self.ready
	_rich_text_label.text = TextUtils.tr_paragraph(text)
