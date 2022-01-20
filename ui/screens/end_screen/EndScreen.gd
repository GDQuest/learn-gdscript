extends Control

onready var _content_container := $Layout/MarginContainer/ColumnLayout/MainColumn/MainContent/MarginContainer/ScrollContainer/VBoxContainer


func _ready() -> void:
	for child in _content_container.get_children():
		if child is RichTextLabel:
			child.connect("meta_clicked", OS, "shell_open")
