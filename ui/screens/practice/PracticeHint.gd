tool
class_name PracticeHint
extends Revealer

export(String, MULTILINE) var bbcode_text: String setget set_bbcode_text

onready var _rich_text_label := $RichTextLabel as RichTextLabel


func set_bbcode_text(new_text: String) -> void:
	bbcode_text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	_rich_text_label.bbcode_text = bbcode_text
