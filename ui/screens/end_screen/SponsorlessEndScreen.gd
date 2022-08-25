extends Control

onready var _outliner_button := $Layout/TopBar/MarginContainer/ToolBarLayout/OutlinerButton


func _ready() -> void:
	_outliner_button.connect("pressed", self, "_on_outliner_button_pressed")


func _on_outliner_button_pressed() -> void:
	NavigationManager.emit_signal("outliner_navigation_requested")
	hide()
