extends Control

onready var _rich_text_label := $RichTextLabel as RichTextLabel


func _ready():
	_rich_text_label.connect("meta_clicked", self, "_on_meta_clicked")


func _on_meta_clicked(data) -> void:
	if typeof(data) == TYPE_STRING:
		if data.begins_with("https://"):
			OS.shell_open(data)
