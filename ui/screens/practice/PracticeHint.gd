tool
class_name PracticeHint
extends Revealer

export(String, MULTILINE) var bbcode_text: String setget set_bbcode_text

onready var _rich_text_label := $RichTextLabel as RichTextLabel


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_rich_text_label):
			_rich_text_label.bbcode_text = tr(bbcode_text)


func set_bbcode_text(new_text: String) -> void:
	bbcode_text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	_rich_text_label.bbcode_text = tr(bbcode_text)
