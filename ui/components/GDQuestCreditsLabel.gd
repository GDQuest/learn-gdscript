extends Control

@onready var _rich_text_label := $RichTextLabel as RichTextLabel

func _ready() -> void:
	_rich_text_label.meta_clicked.connect(_on_meta_clicked)


func _on_meta_clicked(data: Variant) -> void:
	if data is String:
		var link: String = data
		if link.begins_with("https://"):
			OS.shell_open(link)
