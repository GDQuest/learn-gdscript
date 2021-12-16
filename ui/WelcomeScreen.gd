extends Control

signal course_requested()

onready var _settings_button := $Layout/MarginContainer/ColumnLayout/SideColumn/SettingsButton as Button
onready var _start_button := $Layout/MarginContainer/ColumnLayout/SideColumn/StartButton as Button
onready var _report_button := $Layout/TopBar/MarginContainer/ToolBarLayout/ReportButton as Button


func _ready() -> void:
	_settings_button.connect("pressed", self, "_on_settings_requested")
	_start_button.connect("pressed", self, "_on_start_requested")
	
	_report_button.connect("pressed", self, "_on_report_form_requested")


func _on_settings_requested() -> void:
	# TODO: Do a global call to open a settings window.
	pass


func _on_start_requested() -> void:
	emit_signal("course_requested")


func _on_report_form_requested() -> void:
	# TODO: Do a global call to open a global issue reporter.
	pass
