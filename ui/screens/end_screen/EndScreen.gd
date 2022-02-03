extends Control

onready var _content_container := $Layout/MarginContainer/ColumnLayout/MainColumn/MainContent/MarginContainer/ScrollContainer/VBoxContainer
onready var _outliner_button := $Layout/TopBar/MarginContainer/ToolBarLayout/OutlinerButton as Button


func _ready() -> void:
	_outliner_button.connect("pressed", self, "_on_outliner_button_pressed")

	for child in _content_container.get_children():
		if child is RichTextLabel:
			child.connect("meta_clicked", OS, "shell_open")


func _on_outliner_button_pressed() -> void:
	NavigationManager.emit_signal("outliner_navigation_requested")
	hide()
