extends Control

@export var _rich_text_label: RichTextLabel


func _ready():
	_rich_text_label.meta_clicked.connect(_on_meta_clicked)


func _on_meta_clicked(data) -> void:
	if typeof(data) == TYPE_STRING:
		var data_string: String = data
		if data_string.begins_with("https://"):
			OS.shell_open(data_string)
