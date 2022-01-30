extends Control

signal course_requested(force_outliner)

onready var _settings_button := $Layout/MarginContainer/ColumnLayout/SideColumn/SettingsButton as Button
onready var _outliner_button := $Layout/MarginContainer/ColumnLayout/SideColumn/OutlinerButton as Button
onready var _start_button := $Layout/MarginContainer/ColumnLayout/SideColumn/StartButton as Button
onready var _report_button := $Layout/TopBar/MarginContainer/ToolBarLayout/ReportButton as Button
onready var _scroll_container := $Layout/MarginContainer/ColumnLayout/MainColumn/MainContent/MarginContainer/ScrollContainer as ScrollContainer

onready var _main_content_block := $Layout/MarginContainer/ColumnLayout/MainColumn/MainContent as Container
onready var _content_list := (
	_main_content_block.get_node("MarginContainer/ScrollContainer/MarginContainer/VBoxContainer") as Container
)


func _ready() -> void:
	_settings_button.connect("pressed", Events, "emit_signal", ["settings_requested"])
	_outliner_button.connect("pressed", self, "_on_outliner_pressed")
	_start_button.connect("pressed", self, "_on_start_requested")
	
	_report_button.connect("pressed", Events, "emit_signal", ["report_form_requested"])
	for child in _content_list.get_children():
		if child is RichTextLabel:
			child.connect("meta_clicked", OS, "shell_open")

	_scroll_container.grab_focus()


func set_button_continue(enable: bool = true) -> void:
	if enable:
		_start_button.text = "Continue Course"
	else:
		_start_button.text = "Start Course"


func _on_outliner_pressed() -> void:
	emit_signal("course_requested", true)


func _on_start_requested() -> void:
	emit_signal("course_requested", false)
