extends Control

signal course_requested(force_outliner)

onready var _settings_button := $Layout/MarginContainer/ColumnLayout/SideColumn/SettingsButton as Button
onready var _outliner_button := $Layout/MarginContainer/ColumnLayout/SideColumn/OutlinerButton as Button
onready var _start_button := $Layout/MarginContainer/ColumnLayout/SideColumn/StartButton as Button
onready var _report_button := $Layout/TopBar/MarginContainer/ToolBarLayout/ReportButton as Button


func _ready() -> void:
	_settings_button.connect("pressed", Events, "emit_signal", ["settings_requested"])
	_outliner_button.connect("pressed", self, "_on_outliner_pressed")
	_start_button.connect("pressed", self, "_on_start_requested")
	
	_report_button.connect("pressed", Events, "emit_signal", ["report_form_requested"])


func set_button_continue() -> void:
	_start_button.text = "Continue the Course"


func _on_outliner_pressed() -> void:
	emit_signal("course_requested", true)


func _on_start_requested() -> void:
	emit_signal("course_requested", false)
