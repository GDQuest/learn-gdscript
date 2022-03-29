extends Control

const COURSE_URL := "https://gdquest.mavenseed.com/courses/learn-to-code-from-zero-with-godot"

onready var _outliner_button := $Layout/TopBar/MarginContainer/ToolBarLayout/OutlinerButton
onready var _text_column := $Layout/PanelContainer/Sky/Control/Panel/Margin/ScrollContainer/Column
onready var _learn_more_button := $Layout/PanelContainer/Sky/Control/Panel/Margin/ScrollContainer/Column/LearnMoreButton


func _ready() -> void:
	_outliner_button.connect("pressed", self, "_on_outliner_button_pressed")
	for node in _text_column.get_children():
		var rtl := node as RichTextLabel
		if not rtl:
			continue
		rtl.connect("meta_clicked", OS, "shell_open")
	_learn_more_button.connect("pressed", OS, "shell_open", [COURSE_URL])


func _on_outliner_button_pressed() -> void:
	NavigationManager.emit_signal("outliner_navigation_requested")
	hide()
