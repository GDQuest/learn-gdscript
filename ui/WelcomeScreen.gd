extends Control

signal course_requested()

onready var _settings_button := $Layout/MarginContainer/ColumnLayout/SideColumn/SettingsButton as Button
onready var _start_button := $Layout/MarginContainer/ColumnLayout/SideColumn/StartButton as Button
onready var _report_button := $Layout/TopBar/MarginContainer/ToolBarLayout/ReportButton as Button


func _ready() -> void:
	_settings_button.connect("pressed", Events, "emit_signal", ["settings_requested"])
	_start_button.connect("pressed", self, "_on_start_requested")
	
	_report_button.connect("pressed", Events, "emit_signal", ["report_form_requested"])


func _on_start_requested() -> void:
	emit_signal("course_requested")
