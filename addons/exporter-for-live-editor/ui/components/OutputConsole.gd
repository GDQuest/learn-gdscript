# This console displays messages. It adds new lines automatically
class_name OutputConsole
extends PanelContainer

signal reference_clicked(file_name, line_nb, character)

onready var _rich_text_label := $MarginContainer/RichTextLabel as RichTextLabel


func _ready() -> void:
	_rich_text_label.bbcode_enabled = true
	_rich_text_label.connect("meta_clicked", self, "_on_meta_clicked")
	LiveEditorMessageBus.connect("print_request", self, "record_message_for_line")


# Adds a message related to a specific line in a specific file
func record_message_for_line(
	type: int, line: String, file_name: String, line_nb: int, character: int
) -> void:
	var url = "(%s:%s:%s) " % [file_name, line_nb, character]
	var prefix = "[url=%s]%s[/url]" % [url, url]
	match type:
		LiveEditorMessageBus.MESSAGE_TYPE.ASSERT:
			record_assert(line, prefix)
		LiveEditorMessageBus.MESSAGE_TYPE.ERROR:
			record_error(line, prefix)
		LiveEditorMessageBus.MESSAGE_TYPE.WARNING:
			record_warning(line, prefix)
		_:
			record(line, prefix)


func record_error(line: String, prefix := "") -> void:
	record("[color=red]%sERROR: " % [prefix] + line + "[/color]")


func record_assert(line: String, prefix := "") -> void:
	record("[color=red]%sASSERT: " % [prefix] + line + "[/color]")


func record_warning(line: String, prefix := "") -> void:
	record("[color=orange]%sWARNING: " % [prefix] + line + "[/color]")


func record(line: String, prefix := "") -> void:
	_rich_text_label.append_bbcode(prefix + line)
	_rich_text_label.newline()


func _on_meta_clicked(meta: String) -> void:
	var meta_array := meta.split(":")
	var file_name := String(meta_array[0])
	var line_nb := int(meta_array[1])
	var character := int(meta_array[2])
	emit_signal("reference_clicked", file_name, line_nb, character)
